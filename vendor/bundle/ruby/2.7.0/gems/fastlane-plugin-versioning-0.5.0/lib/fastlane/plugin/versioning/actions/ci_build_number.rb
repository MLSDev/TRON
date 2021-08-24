module Fastlane
  module Actions
    class CiBuildNumberAction < Action
      def self.run(params)
        if ENV.key?('JENKINS_HOME') || ENV.key?('JENKINS_URL')
          return ENV['BUILD_NUMBER']
        end

        if ENV.key?('TRAVIS')
          return ENV['TRAVIS_BUILD_NUMBER']
        end

        if ENV.key?('CIRCLECI')
          return ENV['CIRCLE_BUILD_NUM']
        end

        if ENV.key?('TEAMCITY_VERSION')
          return ENV['BUILD_NUMBER']
        end

        if ENV.key?('GO_PIPELINE_NAME')
          return ENV['GO_PIPELINE_COUNTER']
        end

        if ENV.key?('bamboo_buildKey')
          return ENV['bamboo_buildNumber']
        end

        if ENV.key?('GITLAB_CI')
          return ENV['CI_PIPELINE_IID'] || ENV['CI_JOB_ID']
        end

        if ENV.key?('XCS')
          return ENV['XCS_INTEGRATION_NUMBER']
        end

        if ENV.key?('BITBUCKET_BUILD_NUMBER')
          return ENV['BITBUCKET_BUILD_NUMBER']
        end

        if ENV.key?('BITRISE_BUILD_NUMBER')
          return ENV['BITRISE_BUILD_NUMBER']
        end

        if ENV.key?('BUDDYBUILD_BUILD_NUMBER')
          return ENV['BUDDYBUILD_BUILD_NUMBER']
        end

        if ENV.key?('APPVEYOR_BUILD_NUMBER')
          return ENV['APPVEYOR_BUILD_NUMBER']
        end

        if ENV.key?('GITHUB_RUN_NUMBER')
          return ENV['GITHUB_RUN_NUMBER']
        end

        UI.error("Cannot detect current CI build number. Defaulting to \"1\".")
        "1"
      end

      def self.description
        "Detects current build number defined by CI system"
      end

      def self.is_supported?(platform)
        true
      end

      def self.authors
        ["Siarhei Fedartsou", "John Douglas"]
      end

      def self.example_code
        [
          'ci_build_number'
        ]
      end

      def self.category
        :building
      end
    end
  end
end
