module Fastlane
  module Actions
    class GetInfoPlistPathAction < Action
      require 'xcodeproj'
      require 'pathname'

      def self.run(params)
        unless params[:xcodeproj]
          if Helper.test?
            params[:xcodeproj] = "/tmp/fastlane/tests/fastlane/xcodeproj/bundle.xcodeproj"
          else
            params[:xcodeproj] = Dir["*.xcodeproj"][0] unless params[:xcodeproj]
          end
        end

        if params[:target]
          path = find_path_using_target(params)
        else
          path = find_path_using_scheme(params)
        end
        path
      end

      def self.find_path_using_target(params)
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

        # This ensures we get correctly resolved variables against present configuration files.
        plist = target.resolved_build_setting('INFOPLIST_FILE', true)
        UI.user_error! 'Cannot resolve Info.plist build setting. Check it\'s defined or try defining it explicitly on the target without variables.' if plist.nil? || plist.empty?

        if !(build_configuration_name = params[:build_configuration_name]).nil?
          plist = plist[build_configuration_name]
          UI.user_error! "Cannot resolve Info.plist build setting for #{build_configuration_name}." if plist.nil?
        else
          plist = plist.values.compact.uniq
          UI.user_error! 'Cannot accurately resolve Info.plist build setting, try specifying :build_configuration_name.' if plist.count > 1
          plist = plist.first
        end

        path = plist.gsub('SRCROOT', project.path.parent.to_path)
        path = File.join(project.path.parent.to_path, path) unless (Pathname.new path).absolute?
        path
      end

      def self.find_path_using_scheme(params)
        config = { project: params[:xcodeproj], scheme: params[:scheme], configuration: params[:build_configuration_name] }
        project = FastlaneCore::Project.new(config)
        project.select_scheme

        path = project.build_settings(key: 'INFOPLIST_FILE')
        unless (Pathname.new path).absolute?
          path = File.join(Pathname.new(project.path).parent.to_path, path)
        end
        path
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Get the version number of your project"
      end

      def self.details
        'This action will return path to Info.plist for specific target in your project.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                                       env_name: "FL_INFO_PLIST_PROJECT",
                                       description: "Optional, you must specify the path to your main Xcode project if it is not in the project root directory or if you have multiple *.xcodeproj's in the root directory",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Please pass the path to the project, not the workspace") if value.end_with? ".xcworkspace"
                                         UI.user_error!("Could not find Xcode project at path '#{File.expand_path(value)}'") if !File.exist?(value) and !Helper.is_test?
                                       end),
          FastlaneCore::ConfigItem.new(key: :target,
                                       env_name: "FL_INFO_PLIST_TARGET",
                                       optional: true,
                                       conflicting_options: [:scheme],
                                       description: "Specify a specific target if you have multiple per project, optional"),
          FastlaneCore::ConfigItem.new(key: :scheme,
                                       env_name: "FL_INFO_PLIST_SCHEME",
                                       optional: true,
                                       conflicting_options: [:target],
                                       description: "Specify a specific scheme if you have multiple per project, optional"),
          FastlaneCore::ConfigItem.new(key: :build_configuration_name,
                                       optional: true,
                                       description: "Specify a specific build configuration if you have different Info.plist build settings for each configuration")
        ]
      end

      def self.authors
        ["SiarheiFedartsou"]
      end

      def self.is_supported?(platform)
        %i[ios mac].include? platform
      end
    end
  end
end
