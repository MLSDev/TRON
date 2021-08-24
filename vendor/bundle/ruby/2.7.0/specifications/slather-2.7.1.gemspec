# -*- encoding: utf-8 -*-
# stub: slather 2.7.1 ruby lib

Gem::Specification.new do |s|
  s.name = "slather".freeze
  s.version = "2.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mark Larsen".freeze]
  s.date = "2021-05-02"
  s.email = ["mark@venmo.com".freeze]
  s.executables = ["slather".freeze]
  s.files = ["bin/slather".freeze]
  s.homepage = "https://github.com/SlatherOrg/slather".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Test coverage reports for Xcode projects".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
    s.add_development_dependency(%q<coveralls>.freeze, ["~> 0.8"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 12.3"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8"])
    s.add_development_dependency(%q<pry>.freeze, ["~> 0.12"])
    s.add_development_dependency(%q<cocoapods>.freeze, ["~> 1.10.beta.1"])
    s.add_development_dependency(%q<json_spec>.freeze, ["~> 1.1"])
    s.add_development_dependency(%q<equivalent-xml>.freeze, ["~> 0.6"])
    s.add_runtime_dependency(%q<clamp>.freeze, ["~> 1.3"])
    s.add_runtime_dependency(%q<xcodeproj>.freeze, ["~> 1.7"])
    s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.11"])
    s.add_runtime_dependency(%q<CFPropertyList>.freeze, [">= 2.2", "< 4"])
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 2.0"])
    s.add_dependency(%q<coveralls>.freeze, ["~> 0.8"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 12.3"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.8"])
    s.add_dependency(%q<pry>.freeze, ["~> 0.12"])
    s.add_dependency(%q<cocoapods>.freeze, ["~> 1.10.beta.1"])
    s.add_dependency(%q<json_spec>.freeze, ["~> 1.1"])
    s.add_dependency(%q<equivalent-xml>.freeze, ["~> 0.6"])
    s.add_dependency(%q<clamp>.freeze, ["~> 1.3"])
    s.add_dependency(%q<xcodeproj>.freeze, ["~> 1.7"])
    s.add_dependency(%q<nokogiri>.freeze, ["~> 1.11"])
    s.add_dependency(%q<CFPropertyList>.freeze, [">= 2.2", "< 4"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
  end
end
