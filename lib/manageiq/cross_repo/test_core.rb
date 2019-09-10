module ManageIQ::CrossRepo
  class TestCore < TestBase
    attr_reader :core_repo, :gem_repos

    def initialize(core_repo, gem_repos)
      @core_repo = Repository.new(core_repo)
      @gem_repos = gem_repos.to_a.map { |repo| Repository.new(repo) }
    end

    def run
      ensure_repo(core_repo)
      gem_repos.each { |gem_repo| ensure_repo(gem_repo) }

      File.write(core_repo.path.join("bundler.d", "overrides.rb"),
        gem_repos.map { |gem| "override_gem \"#{gem.repo}\", :path => \"#{gem.path}\"" }.join("\n")
      ) unless gem_repos.empty?

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