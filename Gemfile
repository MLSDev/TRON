# frozen_string_literal: true
source "https://rubygems.org"

gem 'fastlane', '~>2.170'
gem 'octokit'
gem 'netrc'
gem 'jazzy', '0.13.1'
gem 'cocoapods'
gem 'mime-types'
gem 'cocoapods-trunk'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
