$LOAD_PATH << File.join(__dir__, "lib")
require "manageiq-cross_repo"

require "active_support/core_ext/object/blank"

namespace :test do
  desc "Run core tests"
  task :core do
    puts "core"
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

    ManageIQ::CrossRepo::TestPlugin.new(test_repo, core_ref).run
  end
end
