describe ManageIQ::CrossRepo::Runner::Travis do
  describe "#build_test_script" do
    let(:script_cmd) { nil }
    let(:runner) { described_class.new(script_cmd) }

    before do
      require "yaml"
      allow(YAML).to receive(:load_file).with(described_class::CONFIG_FILE).and_return(YAML.load(travis_yml))
    end

    context "ruby" do
      let(:travis_yml) do
        <<~TRAVIS_YML
          ---
          language: ruby
          cache: bundler
          install: bundle install
          script: bundle exec rake
        TRAVIS_YML
      end

      it "builds a test script" do
        expected_test_script = <<~SCRIPT
          #!/bin/bash

          echo '::group::install'
          bundle install || exit $?
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

            echo '::group::install'
            bundle install || exit $?
            echo '::endgroup::'
            echo '::group::script'
            cat db/schema.rb || exit $?
            echo '::endgroup::'
          SCRIPT

          expect(runner.build_test_script).to eq(expected_test_script)
        end
      end
    end

    context "node_js" do
      let(:travis_yml) do
        <<~TRAVIS_YML
          ---
          language: node_js
          node_js:
          - '16'
          cache:
            yarn: true
          install: yarn
          script: yarn run test
        TRAVIS_YML
      end

      it "builds a test script" do
        expected_test_script = <<~SCRIPT
          #!/bin/bash

          echo '::group::environment'
          source ~/.nvm/nvm.sh
          nvm install 14
          echo '::endgroup::'
          echo '::group::install'
          yarn || exit $?
          echo '::endgroup::'
          echo '::group::script'
          yarn run test || exit $?
          echo '::endgroup::'
        SCRIPT

        expect(runner.build_test_script).to eq(expected_test_script)
      end

      context "with a script_cmd" do
        let(:script_cmd) { "cat yarn.lock" }

        it "builds a test script" do
          expected_test_script = <<~SCRIPT
            #!/bin/bash

            echo '::group::environment'
            source ~/.nvm/nvm.sh
            nvm install 14
            echo '::endgroup::'
            echo '::group::install'
            yarn || exit $?
            echo '::endgroup::'
            echo '::group::script'
            cat yarn.lock || exit $?
            echo '::endgroup::'
          SCRIPT

          expect(runner.build_test_script).to eq(expected_test_script)
        end
      end
    end

    context "with missing sections" do
      let (:travis_yml) do
        <<~TRAVIS_YML
          ---
          language: ruby
          cache: bundler
        TRAVIS_YML
      end

      it "uses the language defaults" do
        expected_test_script = <<~SCRIPT
          #!/bin/bash

          echo '::group::install'
          bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle} || exit $?
          echo '::endgroup::'
          echo '::group::script'
          bundle exec rake || exit $?
          echo '::endgroup::'
        SCRIPT

        expect(runner.build_test_script).to eq(expected_test_script)
      end
    end

    context "with arrays of commands" do
      let (:travis_yml) do
        <<~TRAVIS_YML
          ---
          language: ruby
          cache: bundler
          install: bundle install
          script:
          - bundle exec rake
          - bundle exec rake spec:javascript
        TRAVIS_YML
      end

      it "builds a test script with both commands" do
        expected_test_script = <<~SCRIPT
          #!/bin/bash

          echo '::group::install'
          bundle install || exit $?
          echo '::endgroup::'
          echo '::group::script'
          bundle exec rake || exit $?
          bundle exec rake spec:javascript || exit $?
          echo '::endgroup::'
        SCRIPT

        expect(runner.build_test_script).to eq(expected_test_script)
      end
    end
  end
end
