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

    it "core_repo defaults to ManageIQ/manageiq@master when test_repo is passed" do
      runner = described_class.new(:test_repo => "ManageIQ/manageiq-ui-classic", :repos => [])
      expect(runner.core_repo.identifier).to eq("ManageIQ/manageiq@master")
    end

    it "raises an exception passing different core test repo" do
      expect {
        described_class.new(:test_repo => "ManageIQ/manageiq@master", :repos => ["ManageIQ/manageiq@ivanchuk"])
      }.to raise_error(ArgumentError, "You cannot pass a different core repo when running a core test")
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
end
