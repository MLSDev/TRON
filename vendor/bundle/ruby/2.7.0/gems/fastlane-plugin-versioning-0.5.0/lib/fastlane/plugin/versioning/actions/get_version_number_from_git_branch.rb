module Fastlane
  module Actions
    class GetVersionNumberFromGitBranchAction < Action
      def self.run(params)
        if Helper.test?
          branch = 'releases/release-1.3.5'
        else
          branch = Actions.git_branch
        end

        pattern = params[:pattern].dup
        pattern["#"] = "(.*)"

        match = Regexp.new(pattern).match(branch)
        UI.user_error!("Cannot find version number in git branch '#{branch}' by pattern '#{params[:pattern]}'") unless match
        match[1]
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Extract version number from git branch name"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :pattern,
                             env_name: "FL_VERSION_NUMBER_FROM_GIT_BRANCH_PATTERN",
                             description: "Pattern for branch name, should contain # character in place of version number",
                             default_value: 'release-#',
                             is_string: true)
        ]
      end

      def self.authors
        ["SiarheiFedartsou"]
      end

      def self.is_supported?(platform)
        %i[ios mac android].include? platform
      end
    end
  end
end
