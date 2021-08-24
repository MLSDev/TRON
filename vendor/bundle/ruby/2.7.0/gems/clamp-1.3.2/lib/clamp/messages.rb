# frozen_string_literal: true

module Clamp #:nodoc:

  # Message lookup, to allow localization.
  #
  module Messages

    def messages=(new_messages)
      messages.merge!(new_messages)
    end

    def message(key, options = {})
      string = messages.fetch(key)
      return string if options.empty?

      format string, options
    end

    def clear_messages!
      init_default_messages
    end

    private

    DEFAULTS = {
      too_many_arguments: "too many arguments",
      option_required: "option '%<option>s' is required",
      option_or_env_required: "option '%<option>s' (or env %<env>s) is required",
      option_argument_error: "option '%<switch>s': %<message>s",
      parameter_argument_error: "parameter '%<param>s': %<message>s",
      env_argument_error: "$%<env>s: %<message>s",
      unrecognised_option: "Unrecognised option '%<switch>s'",
      no_such_subcommand: "No such sub-command '%<name>s'",
      no_value_provided: "no value provided",
      default: "default",
      or: "or",
      required: "required",
      usage_heading: "Usage",
      parameters_heading: "Parameters",
      subcommands_heading: "Subcommands",
      options_heading: "Options"
    }.freeze

    def messages
      init_default_messages unless defined?(@messages)
      @messages
    end

    def init_default_messages
      @messages = DEFAULTS.dup
    end

  end

  extend Messages

end
