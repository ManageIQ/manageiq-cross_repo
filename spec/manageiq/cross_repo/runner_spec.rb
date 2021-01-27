describe ManageIQ::CrossRepo::Runner do
  describe "#initialize" do
    it "test_repo defaults to ManageIQ/manageiq@master" do
      runner = described_class.new(:test_repo => nil, :repos => [])
      expect(runner.test_repo.identifier).to eq("ManageIQ/manageiq@master")
    end

    it "core_repo defaults to ManageIQ/manageiq@master" do
      runner = described_class.new(:test_repo => nil, :repos => [])
      expect(runner.core_repo.identifier).to eq("ManageIQ/manageiq@master")
    end

    it "raises an exception passing different core test repo" do
      expect {
        described_class.new(:test_repo => "ManageIQ/manageiq@master", :repos => ["ManageIQ/manageiq@ivanchuk"])
      }.to raise_error(ArgumentError, "You cannot pass a different core repo when running a core test")
    end

    it "raises an exception if you don't pass a repo override" do
      expect {
        described_class.new(:test_repo => "ManageIQ/manageiq-ui-classic", :repos => [])
      }.to raise_error(ArgumentError, "You must pass at least one repo when running a plugin test.")
    end

    it "accepts an alternate test suite" do
      runner = described_class.new(:test_repo => nil, :repos => [], :test_suite => "spec:javascript")
      expect(runner.test_suite).to eq("spec:javascript")
    end

    it "accepts an alternate script command" do
      runner = described_class.new(:test_repo => nil, :repos => [], :script_cmd => "cat db/schema.rb")
      expect(runner.script_cmd).to eq("cat db/schema.rb")
    end
  end

  describe "#build_test_script (private)" do
    let(:runner) do
      described_class.new(:test_repo => nil, :repos => []).tap do |r|
        require "yaml"
        allow(r).to receive(:travis_yml).and_return(YAML.load(travis_yml))
      end
    end

    let(:travis_yml) do
      <<~TRAVIS_YML
        ---
        language: ruby
        cache: bundler
        script: bundle exec rake
      TRAVIS_YML
    end

    it "builds a test script" do
      expected_test_script = <<~SCRIPT
        #!/bin/bash

        echo 'travis_fold:start:script'
        bundle exec rake || exit $?
        echo 'travis_fold:end:script'
      SCRIPT

      expect(runner.send(:build_test_script)).to eq(expected_test_script)
    end

    context "with arrays of commands" do
      let (:travis_yml) do
        <<~TRAVIS_YML
          ---
          language: ruby
          cache: bundler
          script:
          - bundle exec rake
          - bundle exec rake spec:javascript
        TRAVIS_YML
      end

      it "builds a test script with both commands" do
        expected_test_script = <<~SCRIPT
          #!/bin/bash

          echo 'travis_fold:start:script'
          bundle exec rake || exit $?
          bundle exec rake spec:javascript || exit $?
          echo 'travis_fold:end:script'
        SCRIPT

        expect(runner.send(:build_test_script)).to eq(expected_test_script)
      end
    end
  end
end
