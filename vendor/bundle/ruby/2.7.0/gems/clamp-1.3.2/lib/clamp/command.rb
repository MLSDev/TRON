# frozen_string_literal: true

require "clamp/messages"
require "clamp/errors"
require "clamp/help"
require "clamp/option/declaration"
require "clamp/option/parsing"
require "clamp/parameter/declaration"
require "clamp/parameter/parsing"
require "clamp/subcommand/declaration"
require "clamp/subcommand/parsing"

module Clamp

  # {Command} models a shell command.  Each command invocation is a new object.
  # Command options and parameters are represented as attributes
  # (see {Command::Declaration}).
  #
  # The main entry-point is {#run}, which uses {#parse} to populate attributes based
  # on an array of command-line arguments, then calls {#execute} (which you provide)
  # to make it go.
  #
  class Command

    # Create a command execution.
    #
    # @param [String] invocation_path the path used to invoke the command
    # @param [Hash] context additional data the command may need
    #
    def initialize(invocation_path, context = {})
      @invocation_path = invocation_path
      @context = context
    end

    # @return [String] the path used to invoke this command
    #
    attr_reader :invocation_path

    # @return [Array<String>] unconsumed command-line arguments
    #
    attr_reader :remaining_arguments

    # Parse command-line arguments.
    #
    # @param [Array<String>] arguments command-line arguments
    # @return [Array<String>] unconsumed arguments
    #
    def parse(arguments)
      @remaining_arguments = arguments.dup
      parse_options
      parse_parameters
      parse_subcommand
      verify_required_options_are_set
      handle_remaining_arguments
    end

    # Run the command, with the specified arguments.
    #
    # This calls {#parse} to process the command-line arguments,
    # then delegates to {#execute}.
    #
    # @param [Array<String>] arguments command-line arguments
    #
    def run(arguments)
      parse(arguments)
      execute
    end

    # Execute the command (assuming that all options/parameters have been set).
    #
    # This method is designed to be overridden in sub-classes.
    #
    def execute
      raise "you need to define #execute"
    end

    # @return [String] usage documentation for this command
    #
    def help
      self.class.help(invocation_path)
    end

    # Abort with subcommand missing usage error
    #
    # @ param [String] name subcommand_name
    def subcommand_missing(name)
      signal_usage_error(Clamp.message(:no_such_subcommand, name: name))
    end

    include Clamp::Option::Parsing
    include Clamp::Parameter::Parsing
    include Clamp::Subcommand::Parsing

    protected

    attr_accessor :context

    def handle_remaining_arguments
      signal_usage_error Clamp.message(:too_many_arguments) unless remaining_arguments.empty?
    end

    private

    def signal_usage_error(message)
      e = UsageError.new(message, self)
      e.set_backtrace(caller)
      raise e
    end

    def signal_error(message, options = {})
      status = options.fetch(:status, 1)
      e = ExecutionError.new(message, self, status)
      e.set_backtrace(caller)
      raise e
    end

    def request_help
      raise HelpWanted, self
    end

    class << self

      include Clamp::Option::Declaration
      include Clamp::Parameter::Declaration
      include Clamp::Subcommand::Declaration
      include Help

      # An alternative to "def execute"
      def execute(&block)
        define_method(:execute, &block)
      end

      # Create an instance of this command class, and run it.
      #
      # @param [String] invocation_path the path used to invoke the command
      # @param [Array<String>] arguments command-line arguments
      # @param [Hash] context additional data the command may need
      #
      def run(invocation_path = File.basename($PROGRAM_NAME), arguments = ARGV, context = {})
        new(invocation_path, context).run(arguments)
      rescue Clamp::UsageError => e
        $stderr.puts "ERROR: #{e.message}"
        $stderr.puts ""
        $stderr.puts "See: '#{e.command.invocation_path} --help'"
        exit(1)
      rescue Clamp::HelpWanted => e
        puts e.command.help
      rescue Clamp::ExecutionError => e
        $stderr.puts "ERROR: #{e.message}"
        exit(e.status)
      rescue SignalException => e
        exit(128 + e.signo)
      end

    end

  end

end
