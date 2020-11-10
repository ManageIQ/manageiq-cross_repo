require "manageiq/cross_repo/repository"
require "active_support/core_ext/object/blank"

module ManageIQ::CrossRepo
  class Runner
    attr_reader :test_repo, :core_repo, :gem_repos, :script_cmd, :debug

    def initialize(test_repo, repos, script_cmd = "", debug = false)
      @test_repo = Repository.new(test_repo || "ManageIQ/manageiq@master")

      core_repos, @gem_repos = Array(repos).collect { |repo| Repository.new(repo) }.partition(&:core?)
      @core_repo = core_repos.first

      if @test_repo.core?
        raise ArgumentError, "You cannot pass a different core repo when running a core test" if @core_repo.present? && @core_repo != @test_repo

        @core_repo = @test_repo
      else
        raise ArgumentError, "You must pass at least one repo when running a plugin test." if repos.blank?

        @core_repo ||= Repository.new("ManageIQ/manageiq@master")
      end

      @script_cmd = script_cmd.presence || "bundle exec rake"
      @debug      = debug
    end

    def run
      test_repo.ensure_clone
      core_repo.ensure_clone unless test_repo.core?
      prepare_gem_repos
      run_tests
    end

    private

    def run_tests
      with_test_env do
        system!({"TRAVIS_BUILD_DIR" => test_repo.path.to_s}, "bash", "tools/ci/before_install.sh") if ENV["CI"] && File.exist?("tools/ci/before_install.sh")
        system!(env_vars, "bin/setup")
        system!(script_cmd)
      end
    end

    def env_vars
      {"MANAGEIQ_REPO" => core_repo.path.to_s}
    end

    def with_test_env
      Dir.chdir(test_repo.path) do
        Bundler.with_clean_env do
          yield
        end
      end
    end

    def system!(*args)
      if debug
        repo = Dir.pwd.split("/").last(2).join("/")
        puts "\e[36mDEBUG: #{repo} - #{args.join(" ")}\e[0m"
      end
      exit($?.exitstatus) unless system(*args)
    end

    def generate_bundler_d
      bundler_d_path = core_repo.path.join("bundler.d")
      override_path  = bundler_d_path.join("overrides.rb")

      if gem_repos.empty?
        FileUtils.rm_f override_path
      else
        content = gem_repos.map do |gem|
          # If there is a gemspec get the name of the gem from that instead of the repository
          gem_name = gem.path.glob("*.gemspec")&.first&.basename(".gemspec") || gem.repo
          "ensure_gem \"#{gem_name}\", :path => \"#{gem.path}\""
        end.join("\n")
        FileUtils.mkdir_p(bundler_d_path)

        File.write(override_path, content)

        if debug
          puts
          puts "*" * 80
          puts
          puts "Contents of #{override_path}"
          puts
          puts File.read(override_path)
          puts
          puts "*" * 80
          puts
        end
      end
    end

    def prepare_gem_repos
      gem_repos.each { |gem_repo| gem_repo.ensure_clone }
      generate_bundler_d
    end
  end
end
