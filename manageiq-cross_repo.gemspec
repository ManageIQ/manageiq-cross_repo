require_relative 'lib/manageiq/cross_repo/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-cross_repo"
  spec.version       = ManageIQ::CrossRepo::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = %q{ManageIQ CrossRepo testing library}
  spec.description   = %q{ManageIQ CrossRepo testing library}
  spec.homepage      = "https://github.com/ManageIQ/manageiq-cross_repo"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ManageIQ/manageiq-cross_repo"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"

  spec.add_dependency "ffi-libarchive"
  spec.add_dependency "mixlib-archive"
  spec.add_dependency "optimist"
end
