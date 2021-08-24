module Fastlane
  module Actions
    class IncrementVersionNumberInXcodeprojAction < Action
      def self.run(params)
        if params[:version_number]
          next_version_number = params[:version_number]
        else
          case params[:version_source]
          when "xcodeproj"
            current_version = GetVersionNumberFromXcodeprojAction.run(params)
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
          params[:xcodeproj] = "/tmp/fastlane/tests/fastlane/xcodeproj/versioning_fixture_project.xcodeproj"
        else
          params[:xcodeproj] = Dir["*.xcodeproj"][0] unless params[:xcodeproj]
        end

        if params[:target]
          set_version_number_using_target(params, next_version_number)
        elsif params[:build_configuration_name] && params[:scheme]
          set_version_number_using_scheme(params, next_version_number)
        else
          set_all_xcodeproj_version_numbers(params, next_version_number)
        end

        Actions.lane_context[SharedValues::VERSION_NUMBER] = next_version_number
        next_version_number
      end

      def self.set_all_xcodeproj_version_numbers(params, next_version_number)
        project = Xcodeproj::Project.open(params[:xcodeproj])
        configs = project.objects.select { |obj| select_build_configuration_predicate(nil, obj) }
        configs.each do |config|
          config.build_settings["MARKETING_VERSION"] = next_version_number
        end
        project.save
      end

      private_class_method
      def self.select_build_configuration_predicate(name, configuration)
        is_build_valid_configuration = configuration.isa == "XCBuildConfiguration" && !configuration.build_settings["PRODUCT_BUNDLE_IDENTIFIER"].nil?
        is_build_valid_configuration &&= configuration.name == name unless name.nil?
        return is_build_valid_configuration
      end

      def self.set_version_number_using_target(params, next_version_number)
        project = Xcodeproj::Project.open(params[:xcodeproj])
        if params[:target]
          target = project.targets.detect { |t| t.name == params[:target] }
        else
          # firstly we are trying to find modern application target
          target = project.targets.detect do |t|
            t.kind_of?(Xcodeproj::Project::Object::PBXNativeTarget) &&
              t.product_type == 'com.apple.product-type.application'
          end
          target = project.targets[0] if target.nil?
        end

        target.build_configurations.each do |config|
          UI.message "updating #{config.name} to version #{next_version_number}"
          config.build_settings["MARKETING_VERSION"] = next_version_number
        end unless target.nil?

        project.save
      end

      def self.set_version_number_using_scheme(params, next_version_number)
          project = Xcodeproj::Project.open(params[:xcodeproj])
          configs = project.objects.select { |obj| select_build_configuration_predicate(params[:build_configuration_name], obj) }
          configs.each do |config|
            config.build_settings["MARKETING_VERSION"] = next_version_number
          end
          project.save
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Increment build number in xcodeproj"
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
                        description: "Specify a specific build configuration if you have different build settings for each configuration"),
          FastlaneCore::ConfigItem.new(key: :version_source,
                        optional: true,
                        default_value: 'xcodeproj',
                        verify_block: proc do |value|
                          UI.user_error!("Available values are 'xcodeproj' and 'appstore'") unless ['xcodeproj', 'appstore'].include? value
                        end,
                        description: "Source version to increment. Available options: xcodeproj, appstore"),
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

      def self.authors
        ["jdouglas-nz", "neilb01"]
      end

      def self.is_supported?(platform)
        %i[ios mac android].include? platform
      end
    end
  end
    end
