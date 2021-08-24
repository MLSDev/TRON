# Versioning `fastlane` Plugin

![CI Status](https://travis-ci.org/SiarheiFedartsou/fastlane-plugin-versioning.svg?branch=master)
[![License](https://img.shields.io/github/license/SiarheiFedartsou/fastlane-plugin-versioning.svg)](https://github.com/SiarheiFedartsou/fastlane-plugin-versioning/blob/master/LICENSE)
[![Gem](https://img.shields.io/gem/v/fastlane-plugin-versioning.svg?style=flat)](http://rubygems.org/gems/fastlane-plugin-versioning)
[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-versioning)

## Getting Started

This project is a [fastlane](https://github.com/fastlane/fastlane) plugin. To get started with fastlane-plugin-versioning, add it to your project by running:

```bash
fastlane add_plugin versioning
```

## About versioning

Extends fastlane versioning actions. Allows to set/get versions without using agvtool and do some other small tricks.
Note that all schemes that you pass to actions like `increment_version_number_in_plist`, `increment_build_number_in_xcodeproj` or `get_info_plist_path` in `scheme` parameter must be shared.
To make your scheme shared go to "Manage schemes" in Xcode and tick "Shared" checkbox near your scheme.


### what is this `plist_build_setting_support` stuff about?!
If you have a xcodeproject and have updated to Xcode 11, you'll notice that if you change your build and version numbers through the UI, the actual numbers are now stored inside build settings inside build confiugration. The Info.plist file -- where they used to be stored -- now contains build setting variables (looks like `$(CURRENT_PROJECT_VERSION)` or `$(MARKETING_VERSION)`, for build number and version number respectively).
If you are at this migration 'turning point', you have two options. you can either:
1. simply add `plist_build_setting_support: true` to your plist action parameters
2. change the command to be the xcodeproj variants - i.e. `increment_version_number_in_xcodeproj` or `increment_build_number_in_xcodeproj`

these also apply to the `getters` of build and version numbers. 
We will leave the plist actions in, as for those consumers who are limited to their upgrade path.

## Actions

### increment_version_number_in_plist

Increment/set the version number in a Info.plist of specific target. Doesn't use `agvtool` (unlike default `increment_version_number`).

```ruby
increment_version_number_in_plist # Automatically increment patch version number.
increment_version_number_in_plist(
  bump_type: 'patch' # Automatically increment patch version number
)
increment_version_number_in_plist(
  bump_type: 'minor' # Automatically increment minor version number
)
increment_version_number_in_plist(
  bump_type: 'minor',
  omit_zero_patch_version: true # if true omits zero in patch version(so 42.10.0 will become 42.10 and 42.10.1 will remain 42.10.1), default is false
)
increment_version_number_in_plist(
  bump_type: 'major' # Automatically increment major version number
)
increment_version_number_in_plist(
  version_number: '2.1.1' # Set a specific version number
)
increment_version_number_in_plist(
  # Automatically increment patch version number. Use App Store version number as a source.
  version_source: 'appstore'
)
increment_version_number_in_plist(
  # Automatically increment patch version number. Use App Store version number as a source.
  version_source: 'appstore',
  # optional two letter country code: 
  # specify if availability of your app is limited to a certain country
  country: 'at'
)

increment_version_number_in_plist(
  # specify specific version number (optional, omitting it increments patch version number)
  version_number: '2.1.1',   
  # (optional, you must specify the path to your main Xcode project if it is not in the project root directory
  # or if you have multiple xcodeproj's in the root directory)
  xcodeproj: './path/to/MyApp.xcodeproj'  
  # (optional)
  target: 'TestTarget' # or `scheme`
)

increment_version_number_in_plist(
  # specify specific version number (optional, omitting it increments patch version number)
  version_number: '2.1.1',   
  # (optional, you must specify the path to your main Xcode project if it is not in the project root directory
  # or if you have multiple xcodeproj's in the root directory)
  xcodeproj: './path/to/MyApp.xcodeproj'  
  # (optional)
  target: 'TestTarget' # or `scheme`
  plist_build_setting_support: true, # optional, and defaulting to false.
  # setting this will resolve the version number using the relevant build settings from your xcodeproj.
)

```

#### plist_build_setting_support
`get_version_number_from_plist` supports the `plist_build_setting_support` flag, and will either use the other parameters you pass to resolve a particular build configuration to edit, _OR_ change __ALL__ of them.


### get_version_number_from_plist

Get the version number from an Info.plist of specific target. Doesn't use `agvtool` (unlike default `get_version_number`).

```ruby
version = get_version_number_from_plist(xcodeproj: 'Project.xcodeproj', # optional
                                        target: 'TestTarget', # optional, or `scheme`
                                        # optional, must be specified if you have different Info.plist build settings
                                        # for different build configurations
                                        plist_build_setting_support: true, # optional, and defaulting to false. setting this will 
                                        # resolve the version number using the relevant build settings from your xcodeproj.
                                        build_configuration_name: 'Release')
```

#### plist_build_setting_support
`get_version_number_from_plist` supports the `plist_build_setting_support` flag, and will either use the other parameters you pass to resolve a particular build configuration to retrieve, _OR_ pick the first it finds.

### get_app_store_version_number


```ruby
version = get_app_store_version_number(xcodeproj: 'Project.xcodeproj', # optional
                                       target: 'TestTarget', # optional, or `scheme`
                                       # optional, must be specified if you have different Info.plist build settings
                                       # for different build configurations
                                       build_configuration_name: 'Release')

version = get_app_store_version_number(xcodeproj: 'Project.xcodeproj', # optional
                                       target: 'TestTarget', # optional, or `scheme`
                                       # optional, must be specified if you have different Info.plist build settings
                                       # for different build configurations
                                       build_configuration_name: 'Release',
                                       # optional, must be specified for the lookup to succeed, 
                                       # if your app is only published to one country 
                                       # passed value must be a country code
                                       country: 'at')

version = get_app_store_version_number(bundle_id: 'com.apple.Numbers')

version = get_app_store_version_number(bundle_id: 'com.apple.Numbers',
                                       # optional two letter country code: 
                                       # specify if availability of your app is limited to a certain country
                                       country: 'at')

```

### get_version_number_from_git_branch

```ruby
# Extracts version number from git branch name.
# `pattern` is pattern by which version number will be found, `#` is place where action must find version number.
# Default value is 'release-#'(for instance for branch name 'releases/release-1.5.0' will extract '1.5.0')
version = get_version_number_from_git_branch(pattern: 'release-#')

```

### increment_build_number_in_plist

Increment/set build number in Info.plist of specific target. Doesn't use `agvtool` (unlike default `increment_version_number`).

```ruby
increment_build_number_in_plist # Automatically increments the last part of the build number.
increment_build_number_in_plist(
  build_number: 42 # set build number to 42
)
```

#### plist_build_setting_support
`increment_build_number_in_plist` supports the `plist_build_setting_support` flag, and will either use the other parameters you pass to resolve a particular build configuration to edit, _OR_ change __ALL__ of them.

### get_build_number_from_plist

Get the build number from an Info.plist of specific target. Doesn't use `agvtool` (unlike default `get_build_number`).

```ruby
version = get_build_number_from_plist(xcodeproj: "Project.xcodeproj", # optional
                                        target: 'TestTarget', # optional, or `scheme`
                                        plist_build_setting_support: true, # optional, and defaulting to false. setting this will 
                                        # resolve the build number using the relevant build settings from your xcodeproj.
                                        build_configuration_name: 'Release') # optional, must be specified if you have different Info.plist build settings for different build configurations
```

#### plist_build_setting_support
`get_build_number_from_plist` supports the `plist_build_setting_support` flag, and will either use the other parameters you pass to resolve a particular build configuration to retrieve, _OR_ pick the first it finds.

### get_build_number_from_xcodeproj

Get the build number from a xcodeproj - specific to a target. Doesn't use `agvtool` (unlike default `get_build_number`).

```ruby
version = get_build_number_from_xcodeproj(xcodeproj: "Project.xcodeproj", # optional
                                        target: 'TestTarget', # optional, or `scheme`
                                        build_configuration_name: 'Release') # optional, must be specified if you have different Info.plist build settings for different build configurations
```

### get_version_number_from_xcodeproj

Get the version number from a xcodeproj - specific to a target. Doesn't use `agvtool` (unlike default `get_build_number`).

```ruby
version = get_version_number_from_xcodeproj(xcodeproj: 'Project.xcodeproj', # optional
                                        target: 'TestTarget', # optional, or `scheme`
                                        # optional, must be specified if you have different Info.plist build settings
                                        # for different build configurations
                                        build_configuration_name: 'Release')
```

### increment_version_number_in_xcodeproj

Increment/set the version number in a xcodeproj of specific target. Doesn't use `agvtool` (unlike default `increment_version_number`).

```ruby
increment_version_number_in_xcodeproj # Automatically increment patch version number.
increment_version_number_in_xcodeproj(
  bump_type: 'patch' # Automatically increment patch version number
)
increment_version_number_in_xcodeproj(
  bump_type: 'minor' # Automatically increment minor version number
)
increment_version_number_in_xcodeproj(
  bump_type: 'minor',
  omit_zero_patch_version: true # if true omits zero in patch version(so 42.10.0 will become 42.10 and 42.10.1 will remain 42.10.1), default is false
)
increment_version_number_in_xcodeproj(
  bump_type: 'major' # Automatically increment major version number
)
increment_version_number_in_xcodeproj(
  version_number: '2.1.1' # Set a specific version number
)
increment_version_number_in_xcodeproj(
  # Automatically increment patch version number. Use App Store version number as a source.
  version_source: 'appstore'
)
increment_version_number_in_xcodeproj(
  # Automatically increment patch version number. Use App Store version number as a source.
  version_source: 'appstore',
  # optional two letter country code: 
  # specify if availability of your app is limited to a certain country
  country: 'at'
)

increment_version_number_in_xcodeproj(
  # specify specific version number (optional, omitting it increments patch version number)
  version_number: '2.1.1',   
  # (optional, you must specify the path to your main Xcode project if it is not in the project root directory
  # or if you have multiple xcodeproj's in the root directory)
  xcodeproj: './path/to/MyApp.xcodeproj'  
  # (optional)
  target: 'TestTarget' # or `scheme`
)

```

### get_version_number_from_plist

Get version number from Info.plist of specific target. Doesn't use agvtool (unlike default `get_version_number`).

```ruby
version = get_version_number_from_plist(xcodeproj: 'Project.xcodeproj', # optional
                                        target: 'TestTarget', # optional, or `scheme`
                                        # optional, must be specified if you have different Info.plist build settings
                                        # for different build configurations
                                        plist_build_setting_support: true, # optional, and defaulting to false. setting this will 
                                        # resolve the version number using the relevant build settings from your xcodeproj.
                                        build_configuration_name: 'Release')
```

#### plist_build_setting_support
`get_version_number_from_plist` supports the `plist_build_setting_support` flag, and will either use the other parameters you pass to resolve a particular build configuration to retrieve, _OR_ pick the first it finds.

### get_app_store_version_number


```ruby
version = get_app_store_version_number(xcodeproj: 'Project.xcodeproj', # optional
                                        target: 'TestTarget', # optional, or `scheme`
                                        # optional, must be specified if you have different Info.plist build settings
                                        # for different build configurations
                                        build_configuration_name: 'Release')
)
version = get_app_store_version_number(bundle_id: 'com.apple.Numbers')

```

### get_info_plist_path

Get a path to target's Info.plist
```ruby
get_info_plist_path(xcodeproj: 'Test.xcodeproj', # optional
                    target: 'TestTarget', # optional, or `scheme`
                    # optional, must be specified if you have different Info.plist build settings
                    # for different build configurations
                    build_configuration_name: 'Release')
```

### ci_build_number

Get CI system build number. Determined using environment variables defined by CI systems. Supports Jenkins, Travis CI, Circle CI, TeamCity, GoCD, Bamboo, Gitlab CI, Xcode Server, Bitbucket Pipelines, BuddyBuild, AppVeyor. Returns `1` if build number cannot be determined. 

```ruby
increment_build_number_in_plist(
  build_number: ci_build_number
)
```



## Issues and Feedback

### SwiftPM

SwiftPM can be tedious when using this plugin, at least in terms of git history and `xcodeproj`s. Up until recently, there were a number of annoyances caused by this plugin (and a downstream dependency of it) because writing to a project file would clobber some of the comment metadata inside of the project file and replace them - leaving you with the actual version change, but a number of other, less desirable changes too to hand pick through (or give up this plugin for). The advice is, update to `>= 0.4.6` of this plugin, and follow [this advice](https://github.com/SiarheiFedartsou/fastlane-plugin-versioning/issues/59#issuecomment-878255057) - which is to make sure not to include the `.git` at the end of your SwiftPM dependency URLs.

### New / Fresh projects

Note that you will need to set the build and version numbers through Xcode's UI at least once to use this plugin without weird `nil:NilClass` issues. See this [issue](https://github.com/SiarheiFedartsou/fastlane-plugin-versioning/issues/60) for context

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

For some more detailed help with plugins problems, check out the [Plugins Troubleshooting](https://github.com/fastlane/fastlane/blob/master/fastlane/docs/PluginsTroubleshooting.md) doc in the main `fastlane` repo.

## Using `fastlane` Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://github.com/fastlane/fastlane/blob/master/fastlane/docs/Plugins.md) in the main `fastlane` repo.

## About `fastlane`

`fastlane` automates building, testing, and releasing your app for beta and app store distributions. To learn more about `fastlane`, check out [fastlane.tools](https://fastlane.tools).
