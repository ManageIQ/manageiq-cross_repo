source "https://rubygems.org"

plugin 'bundler-inject'
require File.join(Bundler::Plugin.index.load_paths("bundler-inject")[0], "bundler-inject") rescue nil

gem "activesupport"
gem "mixlib-archive"
gem "rake"

group :development, :test do
  gem "rspec"
  gem "simplecov"
end
