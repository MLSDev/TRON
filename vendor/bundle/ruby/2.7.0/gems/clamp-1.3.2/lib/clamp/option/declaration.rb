# frozen_string_literal: true

require "clamp/attribute/declaration"
require "clamp/option/definition"

module Clamp
  module Option

    # Option declaration methods.
    #
    module Declaration

      include Clamp::Attribute::Declaration

      def option(switches, type, description, opts = {}, &block)
        Option::Definition.new(switches, type, description, opts).tap do |option|
          block ||= option.default_conversion_block
          define_accessors_for(option, &block)
          declared_options << option
        end
      end

      def find_option(switch)
        recognised_options.find { |o| o.handles?(switch) }
      end

      def declared_options
        @declared_options ||= []
      end

      def recognised_options
        unless @implicit_options_declared ||= false
          declare_implicit_help_option
          @implicit_options_declared = true
        end
        effective_options
      end

      private

      def declare_implicit_help_option
        return false if effective_options.find { |o| o.handles?("--help") }
        help_switches = ["--help"]
        help_switches.unshift("-h") unless effective_options.find { |o| o.handles?("-h") }
        option help_switches, :flag, "print help" do
          request_help
        end
      end

      def effective_options
        ancestors.inject([]) do |options, ancestor|
          options + options_declared_on(ancestor)
        end
      end

      def options_declared_on(ancestor)
        return [] unless ancestor.is_a?(Clamp::Option::Declaration)
        ancestor.declared_options
      end

    end

  end
end
