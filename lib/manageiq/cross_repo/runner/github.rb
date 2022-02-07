require_relative "./base"
require "yaml"

module ManageIQ::CrossRepo
  class Runner
    class Github < Base
      CONFIG_FILE = ".github/workflows/ci.yaml".freeze

      def self.available?
        File.exist?(CONFIG_FILE)
      end

      private

      def ci_config
        github_config = YAML.load_file(CONFIG_FILE)

        steps = github_config["jobs"]["ci"]["steps"]
        language = steps.any? { |s| s["uses"] == "ruby/setup-ruby@v1" } ? "ruby" : "node_js"

        defaults[language].clone.tap do |config|
          script_step = steps.detect { |s| s["name"] == "Run tests" }
          config["script"] = script_step["run"] if script_step
        end
      end
    end
  end
end
