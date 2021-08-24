module Fastlane
  module Actions
    class GetVersionNumberFromXcodeprojAction < Action
      require 'xcodeproj'
      require 'pathname'

      def self.run(params)
        unless params[:xcodeproj]
          if Helper.test?
            params[:xcodeproj] = "/tmp/fastlane/tests/fastlane/xcodeproj/versioning_fixture_project.xcodeproj"
          else
            params[:xcodeproj] = Dir["*.xcodeproj"][0] unless params[:xcodeproj]
          end
        end

        if params[:target]
          version_number = get_version_number_using_target(params)
        else
          version_number = get_version_number_using_scheme(params)
        end

        Actions.lane_context[SharedValues::VERSION_NUMBER] = version_number
        version_number
      end

      def self.get_version_number_using_target(params)
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

        version_number = target.resolved_build_setting('MARKETING_VERSION', true)
        UI.user_error! 'Cannot resolve version number build setting.' if version_number.nil? || version_number.empty?

        if !(build_configuration_name = params[:build_configuration_name]).nil?
          version_number = version_number[build_configuration_name]
          UI.user_error! "Cannot resolve $(MARKETING_VERSION) build setting for #{build_configuration_name}." if version_number.nil?
        else
          version_number = version_number.values.compact.uniq
          UI.user_error! 'Cannot accurately resolve $(MARKETING_VERSION) build setting, try specifying :build_configuration_name.' if version_number.count > 1
          version_number = version_number.first
        end

        version_number
      end

      def self.get_version_number_using_scheme(params)
        config = { project: params[:xcodeproj], scheme: params[:scheme], configuration: params[:build_configuration_name] }
        project = FastlaneCore::Project.new(config)
        project.select_scheme

        build_number = project.build_settings(key: 'MARKETING_VERSION')
        UI.user_error! "Cannot resolve $(MARKETING_VERSION) in for the scheme #{config.scheme} with the name #{params.configuration}" if build_number.nil? || build_number.empty?
        build_number
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Get the version number of your project"
      end

      def self.details
        'Gets the $(MARKETING_VERSION) build setting using the specified parameters, or the first if not enough parameters are passed.'
      end

      def self.available_options
        [
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
        ["jdouglas-nz"]
      end

      def self.is_supported?(platform)
        %i[ios mac].include? platform
      end
    end
  end
end
