require "manageiq/cross_repo/version"
require "manageiq/cross_repo/runner"

require "pathname"

module ManageIQ
  module CrossRepo
    ROOT = Pathname.new("../..").expand_path(__dir__)
    REPOS_DIR = ROOT.join("repos")
  end
end
