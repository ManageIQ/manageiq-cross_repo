$LOAD_PATH << File.join(__dir__, "lib")
require "manageiq-cross_repo"

def usage
  <<~USAGE
    Usage:
      bundle exec rake

    Examples:
    # Test a specific plugin against ManageIQ master
    TEST_REPO=manageiq-ui-classic bundle exec rake

    # Test a specific plugin against a particular ManageIQ SHA
    TEST_REPO=manageiq-ui-classic CORE_REPO=manageiq@1234abcd bundle exec rake

    # To test a specific plugin branch against a particular ManageIQ SHA
    TEST_REPO=manageiq-ui-classic@branch-name CORE_REPO=manageiq@1234abcd bundle exec rake

    # To test a specific plugin branch with a set of other plugins
    TEST_REPO=manageiq-ui-classic@feature GEM_REPOS=manageiq-providers-vmware@feature,manageiq-providers-amazon@feature bundle exec rake

    # To test a specific plugin branch with a particular ManageIQ SHA and a set of other plugins
    TEST_REPO=manageiq-ui-classic@feature CORE_REPO=manageiq@1234abcd GEM_REPOS=manageiq-providers-vmware@feature,manageiq-providers-amazon@feature bundle exec rake

    # To run the core tests with ManageIQ master using a specific gem version
    GEM_REPOS=johndoe/manageiq-ui-classic@branch-name bundle exec rake

    # To run the core tests for a branch and a set of gems
    TEST_REPO=johndoe/manageiq@feature GEM_REPOS=johndoe/manageiq-ui-classic@feature,johndoe/manageiq-api@feature bundle exec rake
  USAGE
end

task :test do
  test_repo = ENV["TEST_REPO"]
  core_repo = ENV["CORE_REPO"]
  gem_repos = ENV["GEM_REPOS"]&.split(",")

  begin
    ManageIQ::CrossRepo::Runner.new(test_repo, core_repo, gem_repos).run
  rescue ArgumentError => e
    STDERR.puts "ERROR: #{e}"
    STDERR.puts
    STDERR.puts usage
    exit 1
  end
end

task :default => :test
