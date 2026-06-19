require "manageiq/cross_repo/repository"
require "active_support/core_ext/class/subclasses"
require "active_support/core_ext/object/blank"
Dir.glob(File.join(__dir__, "runner", "*")).sort.each { |f| require f }

module ManageIQ::CrossRepo
  class Runner
    attr_reader :test_repo, :core_repo, :gem_repos, :test_suite, :script_cmd

    def initialize(test_repo:, repos:, test_suite: nil, script_cmd: nil)
      @test_repo = Repository.new(test_repo || "ManageIQ/manageiq@master")

      core_repos, @gem_repos = Array(repos).collect { |repo| Repository.new(repo) }.partition(&:core?)
      @core_repo = core_repos.first

      if @test_repo.core?
        raise ArgumentError, "You cannot pass a different core repo when running a core test" if @core_repo.present? && @core_repo != @test_repo

        @core_repo = @test_repo
      else
        @core_repo ||= Repository.new("ManageIQ/manageiq@master")
      end

      @script_cmd = script_cmd.presence
      @test_suite = test_suite.presence
    end

    def run
      announce_run
      test_repo.ensure_clone
      core_repo.ensure_clone unless test_repo.core?
      prepare_gem_repos
      run_tests
    end

    private

    def announce_run
      puts "\e[36m Starting cross repo for:\e[0m"
      puts "  \e[36mtest repo: #{test_repo.identifier}\e[0m"
      puts "  \e[36mcore repo: #{core_repo.identifier}\e[0m"
      gem_repos.each do |gr|
        puts "  \e[36mgem repo:  #{gr.identifier}\e[0m"
      end
    end

    def bundle_path
      app_path = Pathname.new(ENV["TRAVIS_BUILD_DIR"].presence || Pathname.pwd)
      app_path.join("vendor", "bundle")
    end

    def run_tests
      with_test_env do
        test_script = script_source.new(script_cmd).build_test_script
        run_test_script(test_script)
      end
    end

    def env_vars
      {
        "MANAGEIQ_REPO" => core_repo.path.to_s,
        "BUNDLE_PATH" => bundle_path.to_s,
        "TEST_SUITE" => test_suite,
          "CI"                      => "true",
          "GITHUB_BASE_REF"         => "oparin", # TODO: test_repo.base_ref,
          "GITHUB_REF_NAME"         => test_repo.ref || test_repo.sha,
          "GITHUB_REPOSITORY"       => test_repo.identifier,
          "GITHUB_REPOSITORY_OWNER" => test_repo.org,
          "GITHUB_SERVER_URL"       => "https://github.com"
      }
    end

    def with_test_env
      Dir.chdir(test_repo.path) do
        Bundler.with_unbundled_env do
          yield
        end
      end
    end

    def system!(*args)
      if ENV["DEBUG"]
        repo = Dir.pwd.split("/").last(2).join("/")
        puts "\e[36mDEBUG: #{repo} - #{args.join(" ")}\e[0m"
      end

      Process.wait(spawn(*args))
      exit($?.exitstatus) unless $?.success?
    end

    def script_source
      Base.descendants.detect(&:available?)
    end

    def generate_bundler_d
      bundler_d_path = core_repo.path.join("bundler.d")
      override_path  = bundler_d_path.join("overrides.rb")

      require "fileutils"

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
      end
    end

    def prepare_gem_repos
      gem_repos.each { |gem_repo| gem_repo.ensure_clone }
      generate_bundler_d
    end

    def run_test_script(test_script)
      r, w = IO.pipe
      w.write(test_script)
      w.close

      puts "** AG: #{env_vars.inspect}"
      puts "** AG: #{test_script.inspect}"

      system!(env_vars, "/bin/bash -s", :in => r, :out => $stdout, :err => $stderr)
    end
  end
end
