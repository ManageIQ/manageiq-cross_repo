require_relative "./base"
require "yaml"

module ManageIQ::CrossRepo
  class Runner
    class Travis < Base
      CONFIG_FILE = ".travis.yml".freeze

      def self.available?
        File.exist?(CONFIG_FILE)
      end

      private

      def commands
        environment_setup_commands + section_commands
      end

      def environment_setup_commands
        commands = []

        if config["node_js"]
          commands << "source ~/.nvm/nvm.sh"
          commands += Array(config["node_js"]).map do |node_version|
            "nvm install #{node_version}"
          end
        end

        commands.any? ? build_section("environment", *commands) : commands
      end

      def section_commands
        sections = %w[before_install install before_script script]
        sections.flat_map do |section|
          commands = build_section_commands(section)
          build_section(section, *commands) if commands.present?
        end.compact
      end

      def build_section_commands(section)
        # Travis sections can have a single command or an array of commands
        Array(config[section]).map { |cmd| "#{cmd} || exit $?" }
      end

      def load_config!
        ci_config.tap do |config|
          # Set missing sections to the proper defaults
          config["install"] ||= defaults[config["language"]]["install"]

          config["script"] = script_cmd if script_cmd.present?
          config["script"] ||= defaults[config["language"]]["script"]
        end
      end

      def ci_config
        YAML.load_file(CONFIG_FILE)
      end
    end
  end
end
