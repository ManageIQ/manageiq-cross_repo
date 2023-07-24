require_relative "./base"
require "yaml"
require "active_support/core_ext/enumerable"

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
        steps_by_name = steps.index_by { |step| step["name"] }

        language = steps.any? { |s| s["uses"].to_s.start_with?("ruby/setup-ruby") } ? "ruby" : "node_js"

        result = {"language" => language}

        result["before_install"] = steps_by_name["Set up system"]["run"] if steps_by_name["Set up system"]
        result["before_script"]  = steps_by_name["Prepare tests"]["run"] if steps_by_name["Prepare tests"]
        result["script"]         = steps_by_name["Run tests"]["run"]     if steps_by_name["Run tests"]

        result
      end
    end
  end
end
