$LOAD_PATH << File.join(__dir__, "lib")
require "manageiq-cross_repo"

require "active_support/core_ext/object/blank"

namespace :test do
  desc "Run core tests"
  task :core do
    test_repo = ENV["TEST_REPO"]
    gem_repos = ENV["GEM_REPOS"]&.split(",")

    # It doesn't make sense to use this without passing anything, since that would
    # be equivalent to just running specs on master
    if test_repo.blank? && gem_repos.blank?
      STDERR.puts "ERROR: must pass either a TEST_REPO or at least one GEM_REPOS"
      exit 1
    end

    test_repo ||= "ManageIQ/manageiq@master"

    ManageIQ::CrossRepo::TestCore.new(test_repo, gem_repos).run
  end

  desc "Run plugin tests"
  task :plugin do
    test_repo = ENV["TEST_REPO"]
    core_repo = ENV["CORE_REPO"]
    gem_repos = ENV["GEM_REPOS"]&.split(",")

    if test_repo.blank?
      STDERR.puts "ERROR: TEST_REPO env var must be specfied" if test_repo.blank?
      exit 1
    end

    if core_repo.blank? && gem_repos.blank?
      STDERR.puts "ERROR: must pass either a CORE_REPO or at least one GEM_REPOS"
      exit 1
    end

    core_repo ||= "ManageIQ/manageiq@master"

    ManageIQ::CrossRepo::TestPlugin.new(test_repo, core_repo, gem_repos).run
  end
end
