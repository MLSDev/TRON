# frozen_string_literal: true

module Clamp
  module Subcommand

    Definition = Struct.new(:names, :description, :subcommand_class) do

      def initialize(names, description, subcommand_class)
        names = Array(names)
        super
      end

      def is_called?(name)
        names.member?(name)
      end

      def help
        [names.join(", "), description]
      end

    end

  end
end
