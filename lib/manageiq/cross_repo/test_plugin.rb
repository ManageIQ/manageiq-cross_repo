require "manageiq/cross_repo/repository"

module ManageIQ::CrossRepo
  class TestPlugin
    attr_reader :plugin_repo, :core_repo

    def initialize(repo_name, core_ref)
      @core_repo = Repository.new("manageiq")
      @core_repo.ref = core_ref if core_ref
      @plugin_repo = Repository.new(repo_name)
    end

    def run
      ensure_repo(plugin_repo)
      ensure_repo(core_repo)
      FileUtils.ln_s(core_repo.dir, plugin_repo.dir.join("spec", "manageiq"), :force => true)

      Dir.chdir(plugin_repo.dir) do
        require "bundler"
        Bundler.with_clean_env do
          system!("bin/setup")
          system!("bundle exec rake spec")
        end
      end
    end

    private

    def system!(*args)
      exit($CHILD_STATUS.exitstatus) unless system(*args)
    end

    def ensure_repo(repo)
      return if repo.dir.exist? # TODO: Temporary so it doesn't keep recopying during development

      require "minitar"
      require "open-uri"
      require "tmpdir"
      require "zlib"

      puts "Fetching #{repo.url}"

      Dir.mktmpdir do |dir|
        Minitar.unpack(Zlib::GzipReader.new(open(repo.url, "rb")), dir)

        content_dir = File.join(dir, Dir.children(dir).detect { |d| d != "pax_global_header" })
        FileUtils.mkdir_p(repo.dir.dirname)
        FileUtils.mv(content_dir, repo.dir)
      end
    end
  end
end
