module ManageIQ::CrossRepo
  class Repository
    attr_reader :identifier, :server
    attr_reader :org, :repo, :ref, :sha, :url, :path

    # ManageIQ::CrossRepo::Repository
    #
    # @param identifier [String] the short representation of a repository relative to a server, format [org/]repo[@ref]
    # @param server [String] The git repo server hosting this repository, default: https://github.com
    # @example
    #   Repostory.new("ManageIQ/manageiq@master", server: "https://github.com")
    def initialize(identifier, server: "https://github.com")
      @identifier = identifier
      @server     = server
      @org, @repo, @ref, @sha, @url, @path = parse_identifier
    end

    def core?
      repo.casecmp("manageiq") == 0
    end

    def ensure_clone
      return if path.exist?

      require "mixlib/archive"
      require "open-uri"
      require "tmpdir"
      require "zlib"

      puts "Fetching #{tarball_url}"

      Dir.mktmpdir do |dir|
        Mixlib::Archive.new(open(tarball_url, "rb")).extract(dir)

        content_dir = Pathname.new(dir).children.detect(&:directory?)
        FileUtils.mkdir_p(path.dirname)
        FileUtils.mv(content_dir, path)
      end
    end

    private

    def parse_identifier
      if local_identifier?
        parse_local_identifier
      elsif url_identifier?
        parse_url_identifier
      else
        parse_repo_identifier
      end
    end

    def local_identifier?
      ["/", "~", "."].include?(identifier[0])
    end

    def parse_local_identifier
      path = Pathname.new(identifier).expand_path
      raise ArgumentError, "Path #{path} does not exist" unless path.exist?

      org  = nil
      repo = path.basename.to_s
      ref  = Dir.chdir(path) { `git rev-parse HEAD`.chomp }
      sha  = ref
      url  = nil

      return org, repo, ref, sha, url, path
    end

    def url_identifier?
      identifier.start_with?(server)
    end

    def parse_url_identifier
      url_path = URI.parse(identifier).path
      org_and_repo, pr = url_path.split("/pull/")
      _, org, repo = org_and_repo.split("/")

      url = File.join(server, org, repo)
      sha =
        if pr
          git_pr_to_sha(url, pr)
        else
          git_branch_to_sha(url, "master")
        end

      raise ArgumentError, "#{identifier} does not exist" if sha.nil?

      ref  = nil
      path = REPOS_DIR.join("#{org}/#{repo}@#{sha}")

      return org, repo, ref, sha, url, path
    end

    def parse_repo_identifier
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

      url = File.join(server, org, repo)

      sha =
        if pr
          git_pr_to_sha(url, pr)
        elsif branch
          git_branch_to_sha(url, branch)
        else
          ref
        end

      raise ArgumentError, "#{identifier} does not exist" if sha.nil?

      path = REPOS_DIR.join("#{org}/#{repo}@#{sha}")

      return org, repo, ref, sha, url, path
    end

    def tarball_url
      url && File.join(url, "tarball", sha)
    end

    def git_branch_to_sha(url, branch)
      `git ls-remote #{url} #{branch}`.split("\t").first
    end

    def git_pr_to_sha(url, pr)
      git_branch_to_sha(url, "refs/pull/#{pr}/head")
    end
  end
end
