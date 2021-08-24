# frozen_string_literal: true

require "stringio"
require "clamp/messages"

module Clamp

  # Command help generation.
  #
  module Help

    def usage(usage)
      @declared_usage_descriptions ||= []
      @declared_usage_descriptions << usage
    end

    attr_reader :declared_usage_descriptions

    def description=(description)
      @description = description.dup
      if @description =~ /^\A\n*( +)/
        indent = Regexp.last_match(1)
        @description.gsub!(/^#{indent}/, "")
      end
      @description.strip!
    end

    def banner(description)
      self.description = description
    end

    attr_reader :description

    def derived_usage_description
      parts = ["[OPTIONS]"]
      parts += parameters.map(&:name)
      parts.join(" ")
    end

    def usage_descriptions
      declared_usage_descriptions || [derived_usage_description]
    end

    def help(invocation_path, builder = Builder.new)
      help = builder
      help.add_usage(invocation_path, usage_descriptions)
      help.add_description(description)
      help.add_list(Clamp.message(:parameters_heading), parameters) if has_parameters?
      help.add_list(Clamp.message(:subcommands_heading), recognised_subcommands) if has_subcommands?
      help.add_list(Clamp.message(:options_heading), recognised_options)
      help.string
    end

    # A builder for auto-generated help.
    #
    class Builder

      def initialize
        @lines = []
      end

      def string
        left_column_width = lines.grep(Array).map(&:first).map(&:size).max
        StringIO.new.tap do |out|
          lines.each do |line|
            case line
            when Array
              line[0] = line[0].ljust(left_column_width)
              line.unshift("")
              out.puts(line.join("    "))
            else
              out.puts(line)
            end
          end
        end.string
      end

      def line(text = "")
        @lines << text
      end

      def row(lhs, rhs)
        @lines << [lhs, rhs]
      end

      def add_usage(invocation_path, usage_descriptions)
        line Clamp.message(:usage_heading) + ":"
        usage_descriptions.each do |usage|
          line "    #{invocation_path} #{usage}".rstrip
        end
      end

      def add_description(description)
        return unless description
        line
        line description.gsub(/^/, "  ")
      end

      DETAIL_FORMAT = "    %-29s %s".freeze

      def add_list(heading, items)
        line
        line "#{heading}:"
        items.reject { |i| i.respond_to?(:hidden?) && i.hidden? }.each do |item|
          label, description = item.help
          description.each_line do |line|
            row(label, line)
            label = ""
          end
        end
      end

      private

      attr_accessor :lines

    end

  end

end
