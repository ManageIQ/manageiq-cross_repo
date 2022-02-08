describe ManageIQ::CrossRepo::Runner::Github do
  describe "#build_test_script" do
    let(:script_cmd) { nil }
    let(:runner) { described_class.new(script_cmd) }

    before do
      require "yaml"
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_FILE).and_return(YAML.load(github_yml))
    end

    context "ruby" do
      let(:github_yml) do
        <<~GITHUB_YML
          name: CI

          on: [push, pull_request]

          jobs:
            ci:
              runs-on: ubuntu-latest
              strategy:
                matrix:
                  ruby-version:
                  - '2.6'
                  - '2.7'
              steps:
              - uses: actions/checkout@v2
              - name: Set up system
                run: bin/before_install
              - name: Set up Ruby
                uses: ruby/setup-ruby@v1
                with:
                  ruby-version: ${{ matrix.ruby-version }}
                  bundler-cache: true
              - name: Prepare tests
                run: bin/setup
              - name: Run tests
                run: bundle exec rake
                env:
                  CC_TEST_REPORTER_ID: ${{ secrets.CC_TEST_REPORTER_ID }}
              - if: ${{ github.ref == 'refs/heads/master' && matrix.ruby-version == '2.7' }}
                name: Report code coverage
                continue-on-error: true
                uses: paambaati/codeclimate-action@v3.0.0
                env:
                  CC_TEST_REPORTER_ID: ${{ secrets.CC_TEST_REPORTER_ID }}
        GITHUB_YML
      end

      it "builds a test script" do
        expected_test_script = <<~SCRIPT
          #!/bin/bash

          echo '::group::before_install'
          bin/before_install || exit $?
          echo '::endgroup::'
          echo '::group::install'
          bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle} || exit $?
          echo '::endgroup::'
          echo '::group::before_script'
          bin/setup || exit $?
          echo '::endgroup::'
          echo '::group::script'
          bundle exec rake || exit $?
          echo '::endgroup::'
        SCRIPT

        expect(runner.build_test_script).to eq(expected_test_script)
      end

      context "with a script_cmd" do
        let(:script_cmd) { "cat db/schema.rb" }

        it "builds a test script" do
          expected_test_script = <<~SCRIPT
            #!/bin/bash

            echo '::group::before_install'
            bin/before_install || exit $?
            echo '::endgroup::'
            echo '::group::install'
            bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle} || exit $?
            echo '::endgroup::'
            echo '::group::before_script'
            bin/setup || exit $?
            echo '::endgroup::'
            echo '::group::script'
            cat db/schema.rb || exit $?
            echo '::endgroup::'
          SCRIPT

          expect(runner.build_test_script).to eq(expected_test_script)
        end
      end
    end

    # TODO: Add node_js when we have a node_js repo
    # context "node_js" do
    # end
  end
end
