module Fastlane
  module Actions
    class IncrementVersionNumberInPlistAction < Action
      def self.run(params)
        if params[:version_number]
          next_version_number = params[:version_number]
        else
          case params[:version_source]
          when "plist"
            current_version = GetVersionNumberFromPlistAction.run(params)
          when "appstore"
            current_version = GetAppStoreVersionNumberAction.run(params)
          end

          version_array = current_version.split(".").map(&:to_i)
          case params[:bump_type]
          when "patch"
            version_array[2] = (version_array[2] || 0) + 1
          when "minor"
            version_array[1] = (version_array[1] || 0) + 1
            version_array[2] = version_array[2] = 0
          when "major"
            version_array[0] = (version_array[0] || 0) + 1
            version_array[1] = version_array[1] = 0
            version_array[1] = version_array[2] = 0
          end

          if params[:omit_zero_patch_version] && version_array[2] == 0
            version_array.pop
          end

          next_version_number = version_array.join(".")
        end

        if Helper.test?
          plist = "/tmp/fastlane/tests/fastlane/plist/Info.plist"
        else
          plist = GetInfoPlistPathAction.run(params)
        end

        if current_version =~ /\$\(([\w\-]+)\)/
          UI.important "detected that version is a build setting."
          if params[:plist_build_setting_support]
            UI.important "will continue and update the xcodeproj MARKETING_VERSION instead."
            IncrementVersionNumberInXcodeprojAction.run(params)
          else
            UI.important "will continue and update the info plist key. this will replace the existing value."
            SetInfoPlistValueAction.run(path: plist, key: 'CFBundleShortVersionString', value: next_version_number)
          end
        else
          if params[:plist_build_setting_support]
            UI.important "will update the xcodeproj MARKETING_VERSION."
            IncrementVersionNumberInXcodeprojAction.run(params)
            UI.important "will also update info plist key to be a build setting"
            SetInfoPlistValueAction.run(path: plist, key: 'CFBundleShortVersionString', value: "$(MARKETING_VERSION)")
          else
            UI.important "will update the info plist key. this will replace the existing value."
            SetInfoPlistValueAction.run(path: plist, key: 'CFBundleShortVersionString', value: next_version_number)
          end
        end

        Actions.lane_context[SharedValues::VERSION_NUMBER] = next_version_number
        next_version_number
      end

      def self.description
        "Increment the version number of your project"
      end

      def self.details
        [
          "This action will increment the version number directly in Info.plist. ",
          "unless plist_build_setting_support: true is passed in as parameters"
        ].join("\n")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :bump_type,
                                       env_name: "FL_VERSION_NUMBER_BUMP_TYPE",
                                       description: "The type of this version bump. Available: patch, minor, major",
                                       default_value: "patch",
                                       verify_block: proc do |value|
                                         UI.user_error!("Available values are 'patch', 'minor' and 'major'") unless ['patch', 'minor', 'major'].include? value
                                       end),
          FastlaneCore::ConfigItem.new(key: :version_number,
                                       env_name: "FL_VERSION_NUMBER_VERSION_NUMBER",
                                       description: "Change to a specific version. This will replace the bump type value",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :omit_zero_patch_version,
                                       env_name: "FL_VERSION_NUMBER_OMIT_ZERO_PATCH_VERSION",
                                       description: "If true omits zero in patch version(so 42.10.0 will become 42.10 and 42.10.1 will remain 42.10.1)",
                                       default_value: false,
                                       optional: true,
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :bundle_id,
                                       env_name: "FL_APPSTORE_VERSION_NUMBER_BUNDLE_ID",
                                       description: "Bundle ID of the application",
                                       optional: true,
                                       conflicting_options: %i[xcodeproj target build_configuration_name scheme],
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                                       env_name: "FL_VERSION_NUMBER_PROJECT",
                                       description: "optional, you must specify the path to your main Xcode project if it is not in the project root directory",
                                       optional: true,
                                       conflicting_options: [:bundle_id],
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass the path to the project, not the workspace") if value.end_with? ".xcworkspace"
                                         UI.user_error!("Could not find Xcode project at path '#{File.expand_path(value)}'") if !File.exist?(value) and !Helper.is_test?
                                       end),
          FastlaneCore::ConfigItem.new(key: :target,
                                       env_name: "FL_VERSION_NUMBER_TARGET",
                                       optional: true,
                                       conflicting_options: %i[bundle_id scheme],
                                       description: "Specify a specific target if you have multiple per project, optional"),
          FastlaneCore::ConfigItem.new(key: :scheme,
                                       env_name: "FL_VERSION_NUMBER_SCHEME",
                                       optional: true,
                                       conflicting_options: %i[bundle_id target],
                                       description: "Specify a specific scheme if you have multiple per project, optional"),
          FastlaneCore::ConfigItem.new(key: :build_configuration_name,
                                       optional: true,
                                       conflicting_options: [:bundle_id],
                                       description: "Specify a specific build configuration if you have different Info.plist build settings for each configuration"),
          FastlaneCore::ConfigItem.new(key: :version_source,
                                       optional: true,
                                       default_value: 'plist',
                                       verify_block: proc do |value|
                                         UI.user_error!("Available values are 'plist' and 'appstore'") unless ['plist', 'appstore'].include? value
                                       end,
                                       description: "Source version to increment. Available options: plist, appstore"),
          FastlaneCore::ConfigItem.new(key: :country,
                                       optional: true,
                                       description: "Pass an optional country code, if your app's availability is limited to specific countries",
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :plist_build_setting_support,
                                        description: "support automatic resolution of build setting from xcodeproj if not a literal value in the plist",
                                        is_string: false,
                                        default_value: false)
        ]
      end

      def self.output
        [
          ['VERSION_NUMBER', 'The new version number']
        ]
      end

      def self.authors
        ["SiarheiFedartsou", "jdouglas-nz"]
      end

      def self.is_supported?(platform)
        %i[ios mac].include? platform
      end
    end
  end
end
