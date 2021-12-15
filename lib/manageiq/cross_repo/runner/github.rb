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

      def travis_config
        steps = github_config["jobs"]["ci"]["steps"]
        language = steps.any? { |s| s["uses"] == "ruby/setup-ruby@v1" } ? "ruby" : "node_js"
        defaults[language]
      end

      def github_config
        YAML.load_file(CONFIG_FILE)
      end
    end
  end
end
