# ManageIQ cross-repository testing framework

## Usage

Test a specific plugin against ManageIQ master

```ruby
TEST_REPO=manageiq-ui-classic bundle exec rake test:plugin
```

Test a specific plugin against a particular ManageIQ SHA

```ruby
TEST_REPO=manageiq-ui-classic MANAGEIQ_CORE_REF=1234abcd bundle exec rake test:plugin
```

To test a specific plugin branch against a particular ManageIQ SHA

```ruby
TEST_REPO=manageiq-ui-classic@branch-name MANAGEIQ_CORE_REF=1234abcd bundle exec rake test:plugin
```

To test a specific plugin branch with a particular ManageIQ SHA and a set of other plugins

```ruby
TEST_REPO=manageiq-ui-classic@feature MANAGEIQ_CORE_REF=1234abcd GEM_REPOS=manageiq-providers-vmware@feature,manageiq-providers-amazon@feature
```

To run the core tests with ManageIQ master using a specific gem version

```ruby
GEM_REPOS=johndoe/manageiq-ui-classic@branch-name bundle exec rake test:core
```

To run the core tests for a branch and a set of gems

```ruby
CORE_REPO=johndoe/manageiq@feature GEM_REPOS=johndoe/manageiq-ui-classic@feature,johndoe/manageiq-api@feature bundle exec rake test:core
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
