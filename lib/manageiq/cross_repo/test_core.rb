module ManageIQ::CrossRepo
  class TestCore < TestBase
    attr_reader :test_repo, :gem_repos

    def initialize(test_repo, gem_repos)
      @test_repo = Repository.new(test_repo)
      @gem_repos = gem_repos.to_a.map { |repo| Repository.new(repo) }
    end

    def run
      ensure_repo(test_repo)
      prepare_gem_repos(gem_repos, test_repo)

      Dir.chdir(test_repo.path) do
        Bundler.with_clean_env do
          system!({"TRAVIS_BUILD_DIR" => test_repo.path.to_s}, "bash", "tools/ci/before_install.sh") if ENV["CI"]
          system!("bin/setup")
          system!("bundle exec rake")
        end
      end
    end
  end
end
