# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [2.0.0] - 2022-02-08
### Changed
- Announce the cross repo run information (#81)
- Use Github Actions for CI (#82)
- Replace Travis with Github Actions (#83)

## [1.2.1] - 2022-01-11
### Fixed
- Fix unpacking the hash for ruby 3 support

## [1.2.0] - 2021-12-15
### Changed
- Add support for test repos using Github Actions

### Fixed
- If the list of repos is empty default to the core repo

## [1.1.3] - 2021-08-27
### Changed
- Add retry to ensure_clone (#74)

## [1.1.2] - 2021-05-13
### Changed
- Fix newer activesupport pulling in newer tzinfo and causing automate engine specs to fail

## [1.1.1] - 2021-02-22
### Changed
- [#71] Pass BUNDLE_PATH env var to test script

## [1.1.0] - 2021-02-05
### Changed
- Fix a warning from Kernel#open
- Add a --script-cmd and SCRIPT_CMD option
- Parse .travis.yml and run before_*/install/script sections

## [1.0.4] - 2020-04-14
### Changed
- Run tools/ci/before_install.sh for all plugins

## [1.0.3] - 2020-03-05
### Changed
- Prefer testing using the merge commit if it exists rather than the PR head

## [1.0.2] - 2020-02-04
### Changed
- Fix an issue extracting tgz files smaller than 10Kb
- Fix an issue overriding gems whose repo name doesn't match

[Unreleased]: https://github.com/ManageIQ/more_core_extensions/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/ManageIQ/more_core_extensions/compare/v2.0.0...v1.2.1
[1.2.1]: https://github.com/ManageIQ/more_core_extensions/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/ManageIQ/more_core_extensions/compare/v1.1.3...v1.2.0
[1.1.3]: https://github.com/ManageIQ/more_core_extensions/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/ManageIQ/more_core_extensions/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/ManageIQ/more_core_extensions/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/ManageIQ/more_core_extensions/compare/v1.0.4...v1.1.0
[1.0.4]: https://github.com/ManageIQ/more_core_extensions/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/ManageIQ/more_core_extensions/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/ManageIQ/more_core_extensions/compare/v1.0.1...v1.0.2
