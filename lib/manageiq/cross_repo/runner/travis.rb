require "active_support/core_ext/object/blank"
require "yaml"

module ManageIQ::CrossRepo
  class Runner
    class Travis
      CONFIG_FILE = ".travis.yml".freeze

      def self.available?
        File.exist?(CONFIG_FILE)
      end

      attr_accessor :script_cmd

      def build_test_script(script_cmd = nil)
        @script_cmd = script_cmd.presence

        load_config!

        commands = environment_setup_commands

        sections = %w[before_install install before_script script]
        commands += sections.flat_map do |section|
          # Travis sections can have a single command or an array of commands
          section_commands = Array(config[section]).map { |cmd| "#{cmd} || exit $?" }
          next if section_commands.blank?

          [
            "echo 'travis_fold:start:#{section}'",
            *section_commands,
            "echo 'travis_fold:end:#{section}'"
          ]
        end.compact

        <<~BASH_SCRIPT
          #!/bin/bash

          #{commands.join("\n")}
        BASH_SCRIPT
      end

      private

      def environment_setup_commands
        setup_commands = []

        if config["node_js"]
          setup_commands << "source ~/.nvm/nvm.sh"
          setup_commands += Array(config["node_js"]).map do |node_version|
            "nvm install #{node_version}"
          end
        end

        setup_commands
      end

      def load_config!
        # Set missing sections to the proper defaults
        config["install"] ||= defaults[config["language"]]["install"]

        config["script"] = script_cmd if script_cmd.present?
        config["script"] ||= defaults[config["language"]]["script"]
      end

      def config
        @config ||= YAML.load_file(CONFIG_FILE)
      end

      def defaults
        @defaults ||= {
          "node_js" => {
            "install" => "npm install",
            "script"  => "npm test"
          },
          "ruby"    => {
            "install" => "bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}",
            "script"  => "bundle exec rake"
          }
        }.freeze
      end
    end
  end
end
