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

    def generate_bundler_d(gem_repos, test_repo)
      return if gem_repos.empty?

      bundler_d_path = test_repo.path.join("bundler.d")

      content = gem_repos.map { |gem| "override_gem \"#{gem.repo}\", :path => \"#{gem.path}\"" }.join("\n")

      FileUtils.mkdir_p(bundler_d_path)
      File.write(bundler_d_path.join("overrides.rb"), content)
    end

    def prepare_gem_repos(gem_repos, test_repo)
      gem_repos.each { |gem_repo| ensure_repo(gem_repo) }
      generate_bundler_d(gem_repos, test_repo)
    end
  end
end
