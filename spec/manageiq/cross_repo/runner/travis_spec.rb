describe ManageIQ::CrossRepo::Runner::Travis do
  describe "#build_test_script" do
    let(:runner) do
      described_class.new.tap do |r|
        require "yaml"
        allow(r).to receive(:config).and_return(YAML.load(travis_yml))
      end
    end

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

        echo 'travis_fold:start:install'
        bundle install || exit $?
        echo 'travis_fold:end:install'
        echo 'travis_fold:start:script'
        bundle exec rake || exit $?
        echo 'travis_fold:end:script'
      SCRIPT

      expect(runner.build_test_script).to eq(expected_test_script)
    end

    it "builds a test script with a script_cmd" do
      expected_test_script = <<~SCRIPT
        #!/bin/bash

        echo 'travis_fold:start:install'
        bundle install || exit $?
        echo 'travis_fold:end:install'
        echo 'travis_fold:start:script'
        cat db/schema.rb || exit $?
        echo 'travis_fold:end:script'
      SCRIPT

      script_cmd = "cat db/schema.rb"
      expect(runner.build_test_script(script_cmd)).to eq(expected_test_script)
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

          echo 'travis_fold:start:install'
          bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle} || exit $?
          echo 'travis_fold:end:install'
          echo 'travis_fold:start:script'
          bundle exec rake || exit $?
          echo 'travis_fold:end:script'
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

          echo 'travis_fold:start:install'
          bundle install || exit $?
          echo 'travis_fold:end:install'
          echo 'travis_fold:start:script'
          bundle exec rake || exit $?
          bundle exec rake spec:javascript || exit $?
          echo 'travis_fold:end:script'
        SCRIPT

        expect(runner.build_test_script).to eq(expected_test_script)
      end
    end
  end
end
