SHELL := /bin/bash
# Install Tasks

install-iOS:
	true

install-OSX:
	true

install-tvOS:
	true

install-watchOS:
	true

install-carthage:
	true

# install-cocoapods:
# 	true

# install-oss-osx:
# 	sh swiftenv-install.sh

# Run Tasks

test-iOS:
	set -o pipefail && xcodebuild -project TRON.xcodeproj -scheme "TRON iOS" -destination "name=iPhone 6s" -enableCodeCoverage YES test | xcpretty -ct
	bash <(curl -s https://codecov.io/bash)

test-OSX:
	set -o pipefail && xcodebuild -project TRON.xcodeproj -scheme "TRON OSX" -enableCodeCoverage YES test | xcpretty -ct
	bash <(curl -s https://codecov.io/bash)

test-tvOS:
	set -o pipefail && xcodebuild -project TRON.xcodeproj -scheme "TRON tvOS" -destination "name=Apple TV 1080p" -enableCodeCoverage YES test | xcpretty -ct
	bash <(curl -s https://codecov.io/bash)

test-watchOS:
	set -o pipefail && xcodebuild -project TRON.xcodeproj -scheme "TRON watchOS" -destination "name=Apple Watch - 42mm" | xcpretty -c

test-carthage:
	carthage build --no-skip-current --platform iOS
	ls Carthage/build/iOS/TRON.framework

# test-cocoapods:
# 	pod lib lint TRON.podspec --allow-warnings --verbose

# test-oss-osx:
# 	. ~/.swiftenv/init && swift build
