$LOAD_PATH << File.join(__dir__, "lib")
require "manageiq-cross_repo"

require "active_support/core_ext/object/blank"

namespace :test do
  desc "Run core tests"
  task :core do
    core_repo = ENV["CORE_REPO"]
    plugin_repos = ENV["PLUGIN_REPOS"]&.split(",")

    # It doesn't make sense to use this without passing anything, since that would
    # be equivalent to just running specs on master
    if core_repo.blank? && plugin_repos.blank?
      STDERR.puts "ERROR: must pass either a CORE_REPO or at least one PLUGIN_REPOS"
      exit 1
    end

    # If no core repo was specified just use ManageIQ/manageiq@master
    core_repo ||= "ManageIQ/manageiq@master"

    ManageIQ::CrossRepo::TestCore.new(core_repo, plugin_repos).run
  end

  desc "Run plugin tests"
  task :plugin do
    test_repo = ENV["TEST_REPO"]
    core_ref  = ENV["MANAGEIQ_CORE_REF"] || "master"
    if test_repo.blank? || core_ref.blank?
      STDERR.puts "ERROR: TEST_REPO env var must be specfied" if test_repo.blank?
      STDERR.puts "ERROR: CORE_REF env var must be specfied"  if core_ref.blank?
      exit 1
    end

    ManageIQ::CrossRepo::TestPlugin.new(test_repo, "manageiq@#{core_ref}").run
  end
end
