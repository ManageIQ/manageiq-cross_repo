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

      def build_commands
        config.dig("jobs", "ci", "steps").map do |step|
          if step["run"].nil?
            case step["uses"]
            when /ruby\/setup-ruby/
              step["run"] = defaults["ruby"]["install"]
            when /actions\/setup-node/
              step["run"] = defaults["node_js"]["install"]
            else
              next
            end
          end

          build_section(step["name"], "#{step["run"]} || exit $?")
        end.compact
      end

      def load_config!
        ci_config
      end

      def ci_config
        YAML.load_file(CONFIG_FILE)
      end
    end
  end
end
