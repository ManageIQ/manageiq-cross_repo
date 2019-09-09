module ManageIQ::CrossRepo
  class TestPlugin
    attr_reader :repo_name, :repo_ref, :core_ref

    def initialize(repo_name, core_ref)
      plugin_name, plugin_ref = repo_name.split("@")
      @repo_ref  = plugin_ref || "master"
      @repo_name = plugin_name.include?("/") ? plugin_name : "ManageIQ/#{plugin_name}"
      @core_ref  = core_ref
    end

    def repo_dir
      REPOS_DIR.join(repo_name)
    end

    def core_dir
      REPOS_DIR.join("ManageIQ/manageiq")
    end

    def run
      ensure_repo(repo_name, repo_dir, repo_ref)
      ensure_repo("ManageIQ/manageiq", core_dir, core_ref)
      FileUtils.ln_s(core_dir, repo_dir.join("spec", "manageiq"), :force => true)

      Dir.chdir(repo_dir) do
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

    def ensure_repo(repo_name, repo_dir, expected_ref)
      return if repo_dir.exist? # TODO: Temporary so it doesn't keep recopying during development

      require "minitar"
      require "open-uri"
      require "tmpdir"
      require "zlib"

      src_url = "https://github.com/#{repo_name}/tarball/#{expected_ref}"
      puts "Fetching #{src_url}"

      Dir.mktmpdir do |dir|
        Minitar.unpack(Zlib::GzipReader.new(open(src_url, "rb")), dir)

        content_dir = File.join(dir, Dir.children(dir).detect { |d| d != "pax_global_header" })
        FileUtils.mkdir_p(repo_dir.dirname)
        FileUtils.mv(content_dir, repo_dir)
      end
    end
  end
end
