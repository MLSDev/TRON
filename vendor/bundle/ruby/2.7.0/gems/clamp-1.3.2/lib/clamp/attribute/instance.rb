# frozen_string_literal: true

module Clamp
  module Attribute

    # Represents an attribute of a Clamp::Command instance.
    #
    class Instance

      def initialize(attribute, command)
        @attribute = attribute
        @command = command
      end

      attr_reader :attribute, :command

      def defined?
        command.instance_variable_defined?(attribute.ivar_name)
      end

      # get value directly
      def get
        command.instance_variable_get(attribute.ivar_name)
      end

      # set value directly
      def set(value)
        command.instance_variable_set(attribute.ivar_name, value)
      end

      def default
        command.send(attribute.default_method) if command.respond_to?(attribute.default_method, true)
      end

      # default implementation of read_method
      def _read
        set(default) unless self.defined?
        get
      end

      # default implementation of append_method
      def _append(value)
        current_values = get || []
        set(current_values + [value])
      end

      # default implementation of write_method for multi-valued attributes
      def _replace(values)
        set([])
        Array(values).each { |value| take(value) }
      end

      def read
        command.send(attribute.read_method)
      end

      def take(value)
        if attribute.multivalued?
          command.send(attribute.append_method, value)
        else
          command.send(attribute.write_method, value)
        end
      end

      def signal_usage_error(*args)
        command.send(:signal_usage_error, *args)
      end

      def default_from_environment
        return if self.defined?
        return if attribute.environment_variable.nil?
        return unless ENV.key?(attribute.environment_variable)
        # Set the parameter value if it's environment variable is present
        value = ENV[attribute.environment_variable]
        begin
          take(value)
        rescue ArgumentError => e
          signal_usage_error Clamp.message(:env_argument_error, env: attribute.environment_variable, message: e.message)
        end
      end

      def unset?
        if attribute.multivalued?
          read.empty?
        else
          read.nil?
        end
      end

      def missing?
        attribute.required? && unset?
      end

      def verify_not_missing
        signal_usage_error attribute.option_missing_message if missing?
      end

    end

  end
end
