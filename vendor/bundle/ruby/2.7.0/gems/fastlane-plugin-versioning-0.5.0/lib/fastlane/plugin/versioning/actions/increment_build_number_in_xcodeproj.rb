module Fastlane
  module Actions
    class IncrementBuildNumberInXcodeprojAction < Action
      def self.run(params)
        unless params[:xcodeproj]
          if Helper.test?
            params[:xcodeproj] = "/tmp/fastlane/tests/fastlane/xcodeproj/versioning_fixture_project.xcodeproj"
          else
            params[:xcodeproj] = Dir["*.xcodeproj"][0] unless params[:xcodeproj]
          end
        end

        if params[:build_number]
          next_build_number = params[:build_number]
        else
          current_build_number = GetBuildNumberFromXcodeprojAction.run(params)
          build_array = current_build_number.split(".").map(&:to_i)
          build_array[-1] = build_array[-1] + 1
          next_build_number = build_array.join(".")
        end

        if params[:target]
          set_build_number_using_target(params, next_build_number)
        elsif params[:build_configuration_name] && params[:scheme]
          set_build_number_using_scheme(params, next_build_number)
        else
          set_all_xcodeproj_build_numbers(params, next_build_number)
        end
        Actions.lane_context[SharedValues::BUILD_NUMBER] = next_build_number
        next_build_number
      end

      def self.set_all_xcodeproj_build_numbers(params, next_build_number)
        project = Xcodeproj::Project.open(params[:xcodeproj])
        configs = project.objects.select { |obj| select_build_configuration_predicate(nil, obj) }
        configs.each do |config|
          config.build_settings["CURRENT_PROJECT_VERSION"] = next_build_number
        end
        project.save
      end

      private_class_method
      def self.select_build_configuration_predicate(name, configuration)
        is_build_valid_configuration = configuration.isa == "XCBuildConfiguration" && !configuration.build_settings["PRODUCT_BUNDLE_IDENTIFIER"].nil?
        is_build_valid_configuration &&= configuration.name == name unless name.nil?
        return is_build_valid_configuration
      end

      def self.set_build_number_using_target(params, next_build_number)
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
          UI.message "updating #{config.name} to build #{next_build_number}"
          config.build_settings["CURRENT_PROJECT_VERSION"] = next_build_number
        end unless target.nil?

        project.save
      end

      def self.set_build_number_using_scheme(params, next_build_number)
        project = Xcodeproj::Project.open(params[:xcodeproj])
        configs = project.objects.select { |obj| select_build_configuration_predicate(params[:build_configuration_name], obj) }
        configs.each do |config|
          config.build_settings["CURRENT_PROJECT_VERSION"] = next_build_number
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
          FastlaneCore::ConfigItem.new(key: :build_number,
                                      env_name: "FL_BUILD_NUMBER_BUILD_NUMBER",
                                      description: "Change to a specific build number",
                                      optional: true),
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                                         env_name: "FL_VERSION_NUMBER_PROJECT",
                                         description: "Optional, you must specify the path to your main Xcode project if it is not in the project root directory or if you have multiple *.xcodeproj's in the root directory",
                                         optional: true,
                                         verify_block: proc do |value|
                                           UI.user_error!("Please pass the path to the project, not the workspace") if value.end_with? ".xcworkspace"
                                           UI.user_error!("Could not find Xcode project at path '#{File.expand_path(value)}'") if !File.exist?(value) and !Helper.is_test?
                                         end),
          FastlaneCore::ConfigItem.new(key: :target,
                                         env_name: "FL_VERSION_NUMBER_TARGET",
                                         optional: true,
                                         conflicting_options: [:scheme],
                                         description: "Specify a specific target if you have multiple per project, optional"),
          FastlaneCore::ConfigItem.new(key: :scheme,
                                         env_name: "FL_VERSION_NUMBER_SCHEME",
                                         optional: true,
                                         conflicting_options: [:target],
                                         description: "Specify a specific scheme if you have multiple per project, optional"),
          FastlaneCore::ConfigItem.new(key: :build_configuration_name,
                                         optional: true,
                                         description: "Specify a specific build configuration if you have different build settings for each configuration")
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
