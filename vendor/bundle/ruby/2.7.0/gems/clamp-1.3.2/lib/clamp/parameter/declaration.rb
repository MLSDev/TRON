# frozen_string_literal: true

require "clamp/attribute/declaration"
require "clamp/parameter/definition"

module Clamp
  module Parameter

    # Parameter declaration methods.
    #
    module Declaration

      include Clamp::Attribute::Declaration

      def parameters
        @parameters ||= []
      end

      def has_parameters?
        !parameters.empty?
      end

      def parameter(name, description, options = {}, &block)
        Parameter::Definition.new(name, description, options).tap do |parameter|
          define_accessors_for(parameter, &block)
          parameters << parameter
        end
      end

      def inheritable_parameters
        superclass_inheritable_parameters + parameters.select(&:inheritable?)
      end

      def parameter_buffer_limit
        return 0 unless Clamp.allow_options_after_parameters
        return Float::INFINITY if inheritable_parameters.any?(&:multivalued?)
        inheritable_parameters.size
      end

      private

      def superclass_inheritable_parameters
        return [] unless superclass.respond_to?(:inheritable_parameters, true)
        superclass.inheritable_parameters
      end

    end

  end
end
