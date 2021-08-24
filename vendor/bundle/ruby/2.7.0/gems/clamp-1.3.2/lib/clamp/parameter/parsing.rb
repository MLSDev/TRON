# frozen_string_literal: true

module Clamp
  module Parameter

    # Parameter parsing methods.
    #
    module Parsing

      protected

      def parse_parameters
        set_parameters_from_command_line
        default_parameters_from_environment
      end

      private

      def set_parameters_from_command_line
        self.class.parameters.each do |parameter|
          begin
            parameter.consume(remaining_arguments).each do |value|
              parameter.of(self).take(value)
            end
          rescue ArgumentError => e
            signal_usage_error Clamp.message(:parameter_argument_error, param: parameter.name, message: e.message)
          end
        end
      end

      def default_parameters_from_environment
        self.class.parameters.each do |parameter|
          parameter.of(self).default_from_environment
        end
      end

    end

  end
end
