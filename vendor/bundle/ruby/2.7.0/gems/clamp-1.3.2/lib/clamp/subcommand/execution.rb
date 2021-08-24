# frozen_string_literal: true

module Clamp
  module Subcommand

    # Support for subcommand execution.
    #
    # This module is mixed into command instances that have subcommands, overriding
    # default behaviour in {Clamp::Command}.
    #
    module Execution

      # override default Command behaviour

      def execute
        # delegate to subcommand
        subcommand = instantiate_subcommand(subcommand_name)
        subcommand.run(subcommand_arguments)
      end

      private

      def instantiate_subcommand(name)
        subcommand_class = find_subcommand_class(name)
        subcommand = subcommand_class.new(invocation_path_for(name), context)
        self.class.inheritable_attributes.each do |attribute|
          next unless attribute.of(self).defined?
          attribute.of(subcommand).set(attribute.of(self).get)
        end
        subcommand
      end

      def invocation_path_for(name)
        param_names = self.class.parameters.select(&:inheritable?).map(&:name)
        [invocation_path, *param_names, name].join(" ")
      end

      def find_subcommand_class(name)
        subcommand_def = self.class.find_subcommand(name)
        return subcommand_def.subcommand_class if subcommand_def
        subcommand_missing(name)
      end

      def verify_required_options_are_set
        # not required
      end

    end

  end
end
