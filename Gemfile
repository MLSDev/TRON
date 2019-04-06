# frozen_string_literal: true
source "https://rubygems.org"

gem "fastlane"
gem 'octokit'
gem 'netrc'
gem 'jazzy'
gem 'cocoapods', '~> 1.7.0.beta'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
