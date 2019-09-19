module ManageIQ::CrossRepo
  class TestCore < TestBase
    attr_reader :core_repo, :gem_repos

    def initialize(core_repo, gem_repos)
      raise ArgumentError, "You must pass at least one gem to override" if gem_repos.to_a.empty?

      @core_repo = Repository.new(core_repo)
      @gem_repos = gem_repos.to_a.map { |repo| Repository.new(repo) }
    end

    def run
      ensure_repo(core_repo)
      prepare_gem_repos(gem_repos, core_repo)

      Dir.chdir(core_repo.path) do
        Bundler.with_clean_env do
          system!({"TRAVIS_BUILD_DIR" => core_repo.path.to_s}, "bash", "tools/ci/before_install.sh") if ENV["CI"]
          system!("bin/setup")
          system!("bundle exec rake")
        end
      end
    end
  end
end
