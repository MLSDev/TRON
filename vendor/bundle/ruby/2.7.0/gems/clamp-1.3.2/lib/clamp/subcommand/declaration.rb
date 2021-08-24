# frozen_string_literal: true

require "clamp/errors"
require "clamp/subcommand/definition"

module Clamp
  module Subcommand

    # Subcommand declaration methods.
    #
    module Declaration

      def recognised_subcommands
        @recognised_subcommands ||= []
      end

      def subcommand(name, description, subcommand_class = self, &block)
        subcommand_class = Class.new(subcommand_class, &block) if block
        declare_subcommand_parameters unless has_subcommands?
        recognised_subcommands << Subcommand::Definition.new(name, description, subcommand_class)
      end

      def has_subcommands?
        !recognised_subcommands.empty?
      end

      def find_subcommand(name)
        recognised_subcommands.find { |sc| sc.is_called?(name) }
      end

      def find_subcommand_class(*names)
        names.inject(self) do |command_class, name|
          return nil unless command_class
          subcommand = command_class.find_subcommand(name)
          subcommand.subcommand_class if subcommand
        end
      end

      def inheritable_attributes
        recognised_options + inheritable_parameters
      end

      def default_subcommand=(name)
        raise Clamp::DeclarationError, "default_subcommand must be defined before subcommands" if has_subcommands?
        @default_subcommand = name
      end

      def default_subcommand(*args, &block)
        if args.empty?
          @default_subcommand ||= false
        else
          $stderr.puts "WARNING: Clamp default_subcommand syntax has changed; check the README."
          $stderr.puts "  (from #{caller(1..1).first})"
          self.default_subcommand = args.first
          subcommand(*args, &block)
        end
      end

      private

      def declare_subcommand_parameters
        if default_subcommand
          parameter "[SUBCOMMAND]", "subcommand",
                    attribute_name: :subcommand_name,
                    default: default_subcommand,
                    inheritable: false
        else
          parameter "SUBCOMMAND", "subcommand",
                    attribute_name: :subcommand_name,
                    required: false,
                    inheritable: false
        end
        remove_method :default_subcommand_name if method_defined?(:default_subcommand_name)
        parameter "[ARG] ...", "subcommand arguments",
                  attribute_name: :subcommand_arguments,
                  inheritable: false
      end

    end

  end
end
