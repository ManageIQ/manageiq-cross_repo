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

      def travis_config
        YAML.load_file(CONFIG_FILE)
      end
    end
  end
end
