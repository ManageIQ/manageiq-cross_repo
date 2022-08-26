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

      def env_vars
        super.merge(
          "CI"                      => "true",
          "GITHUB_BASE_REF"         => nil, # TODO: test_repo.base_ref,
          "GITHUB_REF_NAME"         => test_repo.ref || test_repo.sha,
          "GITHUB_REPOSITORY"       => test_repo.identifier,
          "GITHUB_REPOSITORY_OWNER" => test_repo.org,
          "GITHUB_SERVER_URL"       => "https://github.com"
        )
      end

      def ci_config
        github_config = YAML.load_file(CONFIG_FILE)

        steps = github_config["jobs"]["ci"]["steps"]
        steps_by_name = steps.index_by { |step| step["name"] }

        language = steps.any? { |s| s["uses"] == "ruby/setup-ruby@v1" } ? "ruby" : "node_js"

        result = {"language" => language}

        result["before_install"] = steps_by_name["Set up system"]["run"] if steps_by_name["Set up system"]
        result["before_script"]  = steps_by_name["Prepare tests"]["run"] if steps_by_name["Prepare tests"]
        result["script"]         = steps_by_name["Run tests"]["run"]     if steps_by_name["Run tests"]

        result
      end
    end
  end
end
