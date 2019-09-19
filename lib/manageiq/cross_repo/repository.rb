module ManageIQ::CrossRepo
  class Repository
    attr_accessor :org, :repo, :ref, :server

    # ManageIQ::CrossRepo::Repository
    #
    # @param identifier [String] the short representation of a repository relative to a server, format [org/]repo[@ref]
    # @param server [String] The git repo server hosting this repository, default: https://github.com
    # @example
    #   Repostory.new("ManageIQ/manageiq@master", server: "https://github.com")
    def initialize(identifier, server: "https://github.com")
      name, ref = identifier.split("@")
      org, repo = name.split("/")
      repo, org = org, "ManageIQ" if repo.nil?

      self.server = server
      self.org    = org
      self.repo   = repo
      self.ref    = ref || "master"
    end

    def name
      "#{org}/#{repo}"
    end

    def url
      File.join(server, org, repo, "tarball", ref)
    end

    def path
      REPOS_DIR.join(name)
    end

    def core?
      repo.casecmp("manageiq") == 0
    end

    def ensure_clone
      return if path.exist? # TODO: Temporary so it doesn't keep recopying during development

      require "minitar"
      require "open-uri"
      require "tmpdir"
      require "zlib"

      puts "Fetching #{url}"

      Dir.mktmpdir do |dir|
        Minitar.unpack(Zlib::GzipReader.new(open(url, "rb")), dir)

        content_dir = File.join(dir, Dir.children(dir).detect { |d| d != "pax_global_header" })
        FileUtils.mkdir_p(path.dirname)
        FileUtils.mv(content_dir, path)
      end
    end
  end
end
