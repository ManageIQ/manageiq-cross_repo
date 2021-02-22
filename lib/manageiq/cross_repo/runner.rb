require "manageiq/cross_repo/repository"
require "active_support/core_ext/object/blank"

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
        raise ArgumentError, "You must pass at least one repo when running a plugin test." if repos.blank?

        @core_repo ||= Repository.new("ManageIQ/manageiq@master")
      end

      @script_cmd = script_cmd.presence
      @test_suite = test_suite.presence
    end

    def run
      test_repo.ensure_clone
      core_repo.ensure_clone unless test_repo.core?
      prepare_gem_repos
      run_tests
    end

    private

    def bundle_path
      app_path = Pathname.new(ENV["TRAVIS_BUILD_DIR"].presence || Pathname.pwd)
      app_path.join("vendor", "bundle")
    end

    def run_tests
      with_test_env do
        run_test_script(build_test_script)
      end
    end

    def env_vars
      {"MANAGEIQ_REPO" => core_repo.path.to_s, "TRAVIS_BUILD_DIR" => test_repo.path.to_s, "BUNDLE_PATH" => bundle_path.to_s, "TEST_SUITE" => test_suite}
    end

    def with_test_env
      Dir.chdir(test_repo.path) do
        Bundler.with_clean_env do
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

      system!(env_vars, "/bin/bash -s", :in => r, :out => $stdout, :err => $stderr)
    end

    def build_test_script
      load_travis_yml!

      commands = environment_setup_commands

      sections = %w[before_install install before_script script]
      commands += sections.flat_map do |section|
        # Travis sections can have a single command or an array of commands
        section_commands = Array(travis_yml[section]).map { |cmd| "#{cmd} || exit $?" }
        next if section_commands.blank?

        [
          "echo 'travis_fold:start:#{section}'",
          *section_commands,
          "echo 'travis_fold:end:#{section}'"
        ]
      end.compact

      <<~BASH_SCRIPT
        #!/bin/bash

        #{commands.join("\n")}
      BASH_SCRIPT
    end

    def environment_setup_commands
      setup_commands = []

      if travis_yml["node_js"]
        setup_commands << "source ~/.nvm/nvm.sh"
        setup_commands += Array(travis_yml["node_js"]).map do |node_version|
          "nvm install #{node_version}"
        end
      end

      setup_commands
    end

    def load_travis_yml!
      # Load the test_repo's .travis.yml file
      travis_yml

      # Set missing travis sections to the proper defaults
      travis_yml["install"] ||= travis_defaults[travis_yml["language"]]["install"]

      travis_yml["script"] = script_cmd if script_cmd.present?
      travis_yml["script"] ||= travis_defaults[travis_yml["language"]]["script"]
    end

    def travis_yml
      @travis_yml ||= begin
        require "yaml"
        YAML.load_file(".travis.yml")
      end
    end

    def travis_defaults
      @travis_defaults ||= {
        "node_js" => {
          "install" => "npm install",
          "script"  => "npm test"
        },
        "ruby"    => {
          "install" => "bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}",
          "script"  => "bundle exec rake"
        }
      }.freeze
    end
  end
end
