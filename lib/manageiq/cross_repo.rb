require "manageiq/cross_repo/version"
require "manageiq/cross_repo/runner"

require "pathname"

module ManageIQ
  module CrossRepo
    REPOS_DIR = Pathname.pwd.join("repos")

    def self.run(**args)
      Runner.new(**args).run
    end
  end
end
