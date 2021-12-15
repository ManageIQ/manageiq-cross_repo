require "active_support/core_ext/object/blank"

module ManageIQ::CrossRepo
  class Runner
    class Travis
      def self.available?
        File.exist?(".travis.yml")
      end

      attr_accessor :script_cmd

      def build_test_script(script_cmd = nil)
        @script_cmd = script_cmd.presence

        load_travis_yml!

        commands = environment_setup_commands

        sections = %w[before_install install before_script script]
        commands += sections.flat_map do |section|
          # Travis sections can have a single command or an array of commands
          section_commands = Array(travis_yml[section]).map { |cmd| "#{cmd} || exit $?" }
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

        if travis_yml["node_js"]
          setup_commands << "source ~/.nvm/nvm.sh"
          setup_commands += Array(travis_yml["node_js"]).map do |node_version|
            "nvm install #{node_version}"
          end
        end

        setup_commands
      end

      def load_travis_yml!
        # Load the test_repo's .travis.yml file
        travis_yml

        # Set missing travis sections to the proper defaults
        travis_yml["install"] ||= travis_defaults[travis_yml["language"]]["install"]

        travis_yml["script"] = script_cmd if script_cmd.present?
        travis_yml["script"] ||= travis_defaults[travis_yml["language"]]["script"]
      end

      def travis_yml
        @travis_yml ||= begin
          require "yaml"
          YAML.load_file(".travis.yml")
        end
      end

      def travis_defaults
        @travis_defaults ||= {
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
