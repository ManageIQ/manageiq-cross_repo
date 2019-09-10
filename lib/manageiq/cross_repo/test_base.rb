require "manageiq/cross_repo/repository"

module ManageIQ::CrossRepo
  class TestBase
    protected

    def system!(*args)
      exit($CHILD_STATUS.exitstatus) unless system(*args)
    end

    def ensure_repo(repo)
      return if repo.path.exist? # TODO: Temporary so it doesn't keep recopying during development

      require "minitar"
      require "open-uri"
      require "tmpdir"
      require "zlib"

      puts "Fetching #{repo.url}"

      Dir.mktmpdir do |dir|
        Minitar.unpack(Zlib::GzipReader.new(open(repo.url, "rb")), dir)

        content_dir = File.join(dir, Dir.children(dir).detect { |d| d != "pax_global_header" })
        FileUtils.mkdir_p(repo.path.dirname)
        FileUtils.mv(content_dir, repo.path)
      end
    end
  end
end
