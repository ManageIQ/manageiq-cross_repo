# ManageIQ cross-repository testing framework

## Usage

```
Usage:
  bundle exec rake

  There are three environment variables that control how the tests are run.

  TEST_REPO: Defaults to `ManageIQ/manageiq@master`. This is the repository
             which will be tested.
  CORE_REPO: Used to specify a different core branch in which plugin tests will
             run. If TEST_REPO is a plugin, defaults to
             `ManageIQ/manageiq@master`. If TEST_REPO is a core repo, this env
             var is not allowed.
  GEM_REPOS: Optional, a comma-separated-list of other plugin/gem overrides
             which are needed to run the tests.

  All of these support the following formats:
    Remote: `[org/]repository[@ref|#pr]`
      `org`:        Optional, defaults to ManageIQ.
      `repository`: Required, the name of the repository.
      `@ref`:       Optional, defaults to master if #pr not set. Can be a
                    branch, tag, or SHA. Mutually exclusive with #pr.
      `#pr`:        Optional, references a pull-request number. Mutually
                    exclusive with @ref.

    Local: Either a fully qualified path or a relative path (e.g. /path/to/repo,
           ~/relative/to/home, ../relative/to/current/dir)

Examples:
  # Test a plugin against ManageIQ master
  TEST_REPO=manageiq-ui-classic \
    bundle exec rake

  # Test a plugin against a ManageIQ SHA
  TEST_REPO=manageiq-ui-classic \
    CORE_REPO=manageiq@1234abcd \
    bundle exec rake

  # Test a plugin branch
  TEST_REPO=manageiq-ui-classic@feature \
    bundle exec rake

  # Test a plugin branch from a fork
  TEST_REPO=johndoe/manageiq-ui-classic@feature \
    bundle exec rake

  # Test a plugin PR
  TEST_REPO=manageiq-ui-classic#1234 \
    bundle exec rake

  # Test a plugin with a set of other plugins
  TEST_REPO=manageiq-ui-classic \
    GEM_REPOS=manageiq-providers-vmware@feature,manageiq-content@feature \
    bundle exec rake

  # Test a plugin branch with a ManageIQ SHA and a set of other plugins
  TEST_REPO=manageiq-ui-classic@feature \
    CORE_REPO=manageiq@1234abcd \
    GEM_REPOS=manageiq-providers-vmware@feature,manageiq-content@feature \
    bundle exec rake

  # Run core tests with ManageIQ master using a gem version
  GEM_REPOS=johndoe/manageiq-ui-classic@feature \
    bundle exec rake

  # Run core tests for a branch and a set of gems
  TEST_REPO=johndoe/manageiq@feature \
    GEM_REPOS=manageiq-providers-vmware@feature,manageiq-content@feature \
    bundle exec rake
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
