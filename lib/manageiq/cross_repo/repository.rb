module ManageIQ::CrossRepo
  class Repository
    attr_accessor :org, :repo, :ref, :server

    # ManageIQ::CrossRepo::Repository
    #
    # #initialize(identifier, server: "https://github.com")
    #
    # identifier can be [org/]repo[@ref]
    def initialize(identifier, server: "https://github.com")
      name, ref = identifier.split("@")
      org, repo = name.split("/")
      if repo.nil?
        repo = org
        org = "ManageIQ"
      end

      self.server = server
      self.org = org
      self.repo = repo
      self.ref = ref || "master"
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
  end
end
