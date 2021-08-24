# -*- encoding: utf-8 -*-
# stub: fastlane-plugin-versioning 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "fastlane-plugin-versioning".freeze
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Siarhei Fiedartsou".freeze, "John Douglas".freeze]
  s.date = "2021-07-19"
  s.email = ["siarhei.fedartsou@gmail.com".freeze, "john.douglas.nz@gmail.com".freeze]
  s.homepage = "https://github.com/SiarheiFedartsou/fastlane-plugin-versioning".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Allows to set/get app version and build number directly to/from Info.plist".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<pry>.freeze, [">= 0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<fastlane>.freeze, [">= 1.93.1"])
  else
    s.add_dependency(%q<pry>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<fastlane>.freeze, [">= 1.93.1"])
  end
end
