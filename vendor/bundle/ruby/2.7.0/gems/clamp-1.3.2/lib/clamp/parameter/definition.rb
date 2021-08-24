# frozen_string_literal: true

require "clamp/attribute/definition"

module Clamp
  module Parameter

    # Represents an parameter of a Clamp::Command class.
    #
    class Definition < Attribute::Definition

      def initialize(name, description, options = {})
        @name = name
        @description = description
        super(options)
        @multivalued = (@name =~ ELLIPSIS_SUFFIX)
        @required = options.fetch(:required) do
          (@name !~ OPTIONAL)
        end
        @inheritable = options.fetch(:inheritable, true)
      end

      attr_reader :name

      def inheritable?
        @inheritable
      end

      def help_lhs
        name
      end

      def consume(arguments)
        raise ArgumentError, Clamp.message(:no_value_provided) if required? && arguments.empty?
        arguments.shift(multivalued? ? arguments.length : 1)
      end

      private

      ELLIPSIS_SUFFIX = / \.\.\.$/
      OPTIONAL = /^\[(.*)\]/

      VALID_ATTRIBUTE_NAME = /^[a-z0-9_]+$/

      def infer_attribute_name
        inferred_name = name.downcase.tr("-", "_").sub(ELLIPSIS_SUFFIX, "").sub(OPTIONAL) { Regexp.last_match(1) }
        raise "cannot infer attribute_name from #{name.inspect}" unless inferred_name =~ VALID_ATTRIBUTE_NAME
        inferred_name += "_list" if multivalued?
        inferred_name
      end

      def required_indicator
        # implied by LHS
      end

    end

  end
end
