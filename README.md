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

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
