require "manageiq/cross_repo/repository"

module ManageIQ::CrossRepo
  class TestPlugin < TestBase
    attr_reader :plugin_repo, :core_repo

    def initialize(plugin_repo, core_repo)
      @core_repo = Repository.new(core_repo)
      @plugin_repo = Repository.new(plugin_repo)
    end

    def run
      ensure_repo(plugin_repo)
      ensure_repo(core_repo)
      FileUtils.ln_s(core_repo.path, plugin_repo.path.join("spec", "manageiq"), :force => true)

      Dir.chdir(plugin_repo.path) do
        Bundler.with_clean_env do
          system!("bin/setup")
          system!("bundle exec rake spec")
        end
      end
    end
  end
end
