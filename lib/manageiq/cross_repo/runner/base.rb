require "active_support/core_ext/object/blank"
require "yaml"

module ManageIQ::CrossRepo
  class Runner
    class Base
      attr_accessor :script_cmd, :config

      def initialize(script_cmd = nil)
        @script_cmd = script_cmd.presence
        @config     = load_config!
      end

      def build_test_script
        load_config!
        build_script
      end

      private

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

      def build_commands
        environment_setup_commands + section_commands
      end

      def build_section_commands(section)
        # Travis sections can have a single command or an array of commands
        Array(config[section]).map { |cmd| "#{cmd} || exit $?" }
      end

      def build_section(section, *commands)
        [
          "echo '::group::#{section}'",
          *commands,
          "echo '::endgroup::'"
        ]
      end

      def build_script
        <<~BASH_SCRIPT
          #!/bin/bash

          #{build_commands.join("\n")}
        BASH_SCRIPT
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
        raise NotImplementedError, "must be implemented in a subclass"
      end

      def defaults
        @defaults ||= {
          "node_js" => {
            "language" => "node_js",
            "node_js"  => ["12"],
            "install"  => "npm install",
            "script"   => "npm test"
          },
          "ruby"    => {
            "language" => "ruby",
            "rvm"      => ["2.7"],
            "install"  => "bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}",
            "script"   => "bundle exec rake"
          }
        }.freeze
      end
    end
  end
end
