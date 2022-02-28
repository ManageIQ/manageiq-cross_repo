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
        <<~BASH_SCRIPT
          #!/bin/bash

          #{commands.join("\n")}
        BASH_SCRIPT
      end

      private

      def commands
        raise NotImplementedError, "must be implemented in a subclass"
      end

      def build_section(section, *commands)
        [
          "echo '::group::#{section}'",
          *commands,
          "echo '::endgroup::'"
        ]
      end

      def load_config!
        raise NotImplementedError, "must be implemented in a subclass"
      end

      def defaults
        @defaults ||= {
          "node_js" => {
            "language" => "node_js",
            "node_js"  => ["14"],
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
