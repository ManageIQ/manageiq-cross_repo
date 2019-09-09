module ManageIQ::CrossRepo
  class TestCore < TestBase
    attr_reader :core_repo, :plugin_repos

    def initialize(core_repo, plugin_repos)
      @core_repo = Repository.new(core_repo)
      @plugin_repos = plugin_repos.to_a.map { |repo| Repository.new(repo) }
    end

    def run
      ensure_repo(core_repo)
      plugin_repos.each { |plugin_repo| ensure_repo(plugin_repo) }

      File.write(core_repo.path.join("bundler.d", "overrides.rb"),
        plugin_repos.map { |plugin| "override_gem \"#{plugin.repo}\", :path => \"#{plugin.path}\"" }.join("\n")
      ) unless plugin_repos.empty?

      Dir.chdir(core_repo.path) do
        require_relative core_repo.path.join("lib", "manageiq", "environment").to_s
        ManageIQ::Environment.create_database_user if ENV["CI"]
        require "bundler"
        Bundler.with_clean_env do
          system!("bin/setup")
          system!("bundle exec rake")
        end
      end
    end
  end
end
