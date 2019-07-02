$LOAD_PATH << File.join(__dir__, "lib")
require "manageiq-cross_repo"

namespace :test do
  desc "Run core tests"
  task :core do
    puts "core"
  end

  desc "Run plugin tests"
  task :plugin do
    ManageIQ::CrossRepo::TestPlugin.new(ENV.fetch("TEST_REPO"), ENV.fetch("MANAGEIQ_CORE_REF", "master")).run
  end
end
