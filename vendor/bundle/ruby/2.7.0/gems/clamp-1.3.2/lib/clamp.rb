# frozen_string_literal: true

require "clamp/version"

require "clamp/command"

def Clamp(&block) # rubocop:disable Naming/MethodName
  Class.new(Clamp::Command, &block).run
end
