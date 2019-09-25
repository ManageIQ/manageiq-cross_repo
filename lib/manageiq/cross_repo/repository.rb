module ManageIQ::CrossRepo
  class Repository
    attr_accessor :org, :repo, :ref, :sha, :url, :path

    # ManageIQ::CrossRepo::Repository
    #
    # @param identifier [String] the short representation of a repository relative to a server, format [org/]repo[@ref]
    # @param server [String] The git repo server hosting this repository, default: https://github.com
    # @example
    #   Repostory.new("ManageIQ/manageiq@master", server: "https://github.com")
    def initialize(identifier, server: "https://github.com")
      @org, @repo, @ref, @sha, @url, @path = parse_identifier(identifier, server)
    end

    def core?
      repo.casecmp("manageiq") == 0
    end

    def ensure_clone
      return if path.exist?

      require "minitar"
      require "open-uri"
      require "tmpdir"
      require "zlib"

      puts "Fetching #{tarball_url}"

      Dir.mktmpdir do |dir|
        Minitar.unpack(Zlib::GzipReader.new(open(tarball_url, "rb")), dir)

        content_dir = File.join(dir, Dir.entries(dir).detect { |d| !['.', '..', "pax_global_header"].include?(d) })
        FileUtils.mkdir_p(path.dirname)
        FileUtils.mv(content_dir, path)
      end
    end

    private

    def parse_identifier(identifier, server)
      if ["/", "~", "."].include?(identifier[0])
        path = Pathname.new(identifier).expand_path
        raise ArgumentError, "Path #{path} does not exist" unless path.exist?

        repo = path.basename.to_s
        ref  = Dir.chdir(path) { `git rev-parse HEAD`.chomp }
        sha  = ref
      else
        if identifier.include?("#")
          name, pr = identifier.split("#")
        else
          name, ref_or_branch = identifier.split("@")
          if ref_or_branch.nil?
            branch = "master"
          elsif ref_or_branch.match?(/^\h+$/)
            ref = ref_or_branch
          else
            branch = ref_or_branch
          end
        end

        org, repo = name.split("/")
        repo, org = org, "ManageIQ" if repo.nil?

        url  = File.join(server, org, repo)

        sha = if pr
          `git ls-remote #{url} refs/pull/#{pr}/head`.split("\t").first
        elsif branch
          `git ls-remote #{url} #{branch}`.split("\t").first
        else
          ref
        end

        raise ArgumentError, "#{identifier} does not exist" if sha.nil?

        path = REPOS_DIR.join("#{org}/#{repo}@#{sha}")
      end

      return org, repo, ref, sha, url, path
    end

    def tarball_url
      url && File.join(url, "tarball", sha)
    end
  end
end
