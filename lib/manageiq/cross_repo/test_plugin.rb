require "manageiq/cross_repo/repository"

module ManageIQ::CrossRepo
  class TestPlugin < TestBase
    attr_reader :test_repo, :core_repo, :gem_repos

    def initialize(test_repo, core_repo, gem_repos)
      @test_repo = Repository.new(test_repo)
      @core_repo = Repository.new(core_repo)
      @gem_repos = gem_repos.to_a.map { |repo| Repository.new(repo) }
    end

    def run
      ensure_repo(test_repo)
      ensure_repo(core_repo)
      prepare_gem_repos(gem_repos, test_repo)

      FileUtils.ln_s(core_repo.path, test_repo.path.join("spec", "manageiq"), :force => true)

      Dir.chdir(test_repo.path) do
        Bundler.with_clean_env do
          system!("bin/setup")
          system!("bundle exec rake spec")
        end
      end
    end
  end
end
