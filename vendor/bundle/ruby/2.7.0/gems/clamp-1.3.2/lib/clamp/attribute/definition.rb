# frozen_string_literal: true

require "clamp/attribute/instance"

module Clamp
  module Attribute

    # Represents an attribute of a Clamp::Command class.
    #
    class Definition

      def initialize(options)
        @attribute_name = options[:attribute_name].to_s if options.key?(:attribute_name)
        @default_value = options[:default] if options.key?(:default)
        @environment_variable = options[:environment_variable] if options.key?(:environment_variable)
        @hidden = options[:hidden] if options.key?(:hidden)
      end

      attr_reader :description, :environment_variable

      def help_rhs
        rhs = description
        comments = required_indicator || default_description
        rhs += " (#{comments})" if comments
        rhs
      end

      def help
        [help_lhs, help_rhs]
      end

      def ivar_name
        "@#{attribute_name}"
      end

      def read_method
        attribute_name
      end

      def default_method
        "default_#{read_method}"
      end

      def write_method
        "#{attribute_name}="
      end

      def append_method
        "append_to_#{attribute_name}" if multivalued?
      end

      def multivalued?
        @multivalued
      end

      def required?
        @required ||= false
      end

      def hidden?
        @hidden ||= false
      end

      def attribute_name
        @attribute_name ||= infer_attribute_name
      end

      def default_value
        if defined?(@default_value)
          @default_value
        elsif multivalued?
          []
        end
      end

      def of(command)
        Attribute::Instance.new(self, command)
      end

      def option_missing_message
        if environment_variable
          Clamp.message(:option_or_env_required,
                        option: switches.first,
                        env: environment_variable)
        else
          Clamp.message(:option_required,
                        option: switches.first)
        end
      end

      private

      def default_description
        default_sources = [
          ("$#{@environment_variable}" if defined?(@environment_variable)),
          (@default_value.inspect if defined?(@default_value))
        ].compact
        return nil if default_sources.empty?
        "#{Clamp.message(:default)}: " + default_sources.join(", #{Clamp.message(:or)} ")
      end

    end

  end
end
