# ManageIQ cross-repository testing framework

Usage: `manageiq-cross_repo --test-repo repo [--core-repo repo] [--gem-repos repo1 repo2 ...]`

ManageIQ cross-repository is a cross repository test framework for the ManageIQ project.
Its purpose is to allow running multiple repository tests suites in the context
of other repositories and is particularly useful when trying to determine if the
changes you are making as a developer will affect the other test suites.

## Options
```  
  -t, --test-repo=<s>     This is the repository which will be tested.
                          Can also be passed as a TEST_REPO environment variable.
                           (default: ManageIQ/manageiq@master)
  -c, --core-repo=<s>     Used to specify a different core branch in which plugin tests will run.
                           If --test-repo is a plugin, defaults to ManageIQ/manageiq@master.
                           If --test-repo is a core repo, this option is not allowed.
                          Can also be passed as a CORE_REPO environment variable.
  -g, --gem-repos=<s+>    Optional, a list of other plugin/gem overrides which are needed to run the tests.
                          Can also be passed as a GEM_REPOS environment variable.

  -v, --version           Print version and exit
  -h, --help              Show this message
```

## Repo Formats
```
  Remote: [org/]repository[@ref|#pr]
    org:        Optional, defaults to ManageIQ.
    repository: Required, the name of the repository.
    @ref:       Optional, defaults to master if #pr not set. Can be a branch, tag, or SHA. Mutually exclusive with #pr.
    #pr:        Optional, references a pull-request number. Mutually exclusive with @ref.

  URL: https://github.com/org/repository, https://github.com/org/repository/tree/branch,
       https://github.com/org/repository/commit/sha, https://github.com/org/repository/pull/pr

  Local: Either a fully qualified path or a relative path (e.g. /path/to/repo, ~/relative/to/home, ../relative/to/current/dir)
```

## Examples

  ### Test a plugin against ManageIQ master
  `manageiq-cross_repo --test-repo manageiq-ui-classic`

  ### Test a plugin against a ManageIQ SHA
  `manageiq-cross_repo --test-repo manageiq-ui-classic --core-repo manageiq@1234abcd`

  ### Test a plugin branch
  `manageiq-cross_repo --test-repo manageiq-ui-classic@feature`

  ### Test a plugin branch from a fork
  `manageiq-cross_repo --test-repo johndoe/manageiq-ui-classic@feature`

  ### Test a plugin PR
  `manageiq-cross_repo --test-repo manageiq-ui-classic#1234`

  ### Test a plugin with a set of other plugins
  `manageiq-cross_repo --test-repo manageiq-ui-classic --gem-repos manageiq-providers-vmware@feature manageiq-content@feature`

  ### Test a plugin branch with a ManageIQ SHA and a set of other plugins
  `manageiq-cross_repo --test-repo manageiq-ui-classic@feature --core-repo manageiq@1234abcd --gem-repos manageiq-providers-vmware@feature manageiq-content@feature`

  ### Run core tests with ManageIQ master using a gem version
  `manageiq-cross_repo --gem-repos johndoe/manageiq-ui-classic@feature`

  ### Run core tests for a branch and a set of gems
  `manageiq-cross_repo --test-repo johndoe/manageiq@feature --gem-repos manageiq-providers-vmware@feature manageiq-content@feature`

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
