# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)
require "clamp/version"

Gem::Specification.new do |s|

  s.name          = "clamp"
  s.version       = Clamp::VERSION.dup
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Mike Williams"]
  s.email         = "mdub@dogbiscuit.org"
  s.homepage      = "https://github.com/mdub/clamp"

  s.license       = "MIT"

  s.summary       = "a minimal framework for command-line utilities"
  s.description   = <<-TEXT.gsub(/^\s+/, "")
    Clamp provides an object-model for command-line utilities.
    It handles parsing of command-line options, and generation of usage help.
  TEXT

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

end
