# frozen_string_literal: true

module Clamp

  # raised to indicate invalid option/parameter declaration
  class DeclarationError < StandardError
  end

  # abstract command runtime error
  class RuntimeError < StandardError

    def initialize(message, command)
      super(message)
      @command = command
    end

    attr_reader :command

  end

  # raised to signal incorrect command usage
  class UsageError < RuntimeError; end

  # raised to request usage help
  class HelpWanted < RuntimeError

    def initialize(command)
      super("I need help", command)
    end

  end

  # raised to signal error during execution
  class ExecutionError < RuntimeError

    def initialize(message, command, status = 1)
      super(message, command)
      @status = status
    end

    attr_reader :status

  end

end
