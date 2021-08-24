# frozen_string_literal: true

require "spec_helper"

describe Clamp::Messages do

  describe "message" do
    before do
      Clamp.messages = {
        too_many_arguments: "Way too many!",
        custom_message: "Say %<what>s to %<whom>s"
      }
    end

    after do
      Clamp.clear_messages!
    end

    it "allows setting custom messages" do
      expect(Clamp.message(:too_many_arguments)).to eql "Way too many!"
    end

    it "fallbacks to a default message" do
      expect(Clamp.message(:no_value_provided)).to eql "no value provided"
    end

    it "formats the message" do
      expect(Clamp.message(:custom_message, what: "hello", whom: "Clamp")).to eql "Say hello to Clamp"
    end
  end

  describe "clear_messages!" do
    it "clears messages to the defualt state" do
      default_msg = Clamp.message(:too_many_arguments).clone

      Clamp.messages = {
        too_many_arguments: "Way too many!"
      }
      Clamp.clear_messages!

      expect(Clamp.message(:too_many_arguments)).to eql default_msg
    end
  end

end
