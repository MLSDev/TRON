# frozen_string_literal: true

require "clamp/attribute/definition"
require "clamp/truthy"

module Clamp
  module Option

    # Represents an option of a Clamp::Command class.
    #
    class Definition < Attribute::Definition

      def initialize(switches, type, description, options = {})
        @switches = Array(switches)
        @type = type
        @description = description
        super(options)
        @multivalued = options[:multivalued]
        return unless options.key?(:required)
        @required = options[:required]
        # Do some light validation for conflicting settings.
        raise ArgumentError, "Specifying a :default value with :required doesn't make sense" if options.key?(:default)
        raise ArgumentError, "A required flag (boolean) doesn't make sense." if type == :flag
      end

      attr_reader :switches, :type

      def long_switch
        switches.find { |switch| switch =~ /^--/ }
      end

      def handles?(switch)
        recognised_switches.member?(switch)
      end

      def flag?
        @type == :flag
      end

      def flag_value(switch)
        !(switch =~ /^--no-(.*)/ && switches.member?("--\[no-\]#{Regexp.last_match(1)}"))
      end

      def read_method
        if flag?
          super + "?"
        else
          super
        end
      end

      def extract_value(switch, arguments)
        if flag?
          flag_value(switch)
        else
          arguments.shift
        end
      end

      def default_conversion_block
        Clamp.method(:truthy?) if flag?
      end

      def help_lhs
        lhs = switches.join(", ")
        lhs += " " + type unless flag?
        lhs
      end

      private

      def recognised_switches
        switches.map do |switch|
          if switch =~ /^--\[no-\](.*)/
            ["--#{Regexp.last_match(1)}", "--no-#{Regexp.last_match(1)}"]
          else
            switch
          end
        end.flatten
      end

      def infer_attribute_name
        raise Clamp::DeclarationError, "You must specify either a long-switch or an :attribute_value" unless long_switch
        inferred_name = long_switch.sub(/^--(\[no-\])?/, "").tr("-", "_")
        inferred_name += "_list" if multivalued?
        inferred_name
      end

      def required_indicator
        Clamp.message(:required) if required?
      end

    end

  end
end
