# frozen_string_literal: true

require "spec_helper"

describe Clamp::Command do

  extend CommandFactory
  include OutputCapture

  context "with allow_options_after_parameters enabled" do

    before do
      Clamp.allow_options_after_parameters = true
    end

    after do
      Clamp.allow_options_after_parameters = false
    end

    given_command("cmd") do

      option ["-v", "--verbose"], :flag, "Be noisy"

      subcommand "say", "Say something" do

        option "--loud", :flag, "say it loud"

        parameter "WORDS ...", "the thing to say", attribute_name: :words

        def execute
          message = words.join(" ")
          message = message.upcase if loud?
          message *= 3 if verbose?
          $stdout.puts message
        end

      end

    end

    it "still works" do
      command.run(%w[say foo])
      expect(stdout).to eql("foo\n")
    end

    it "honours options after positional arguments" do
      command.run(%w[say blah --verbose])
      expect(stdout).to eql("blahblahblah\n")
    end

    it "honours options declared on subcommands" do
      command.run(%w[say --loud blah])
      expect(stdout).to eql("BLAH\n")
    end

  end

end
