#!/bin/bash

# Run the tests
xcodebuild -project FocusZone.xcodeproj -scheme FocusZone -destination 'platform=iOS Simulator,name=iPhone 16' test

# Print the results
xcodebuild -project FocusZone.xcodeproj -scheme FocusZone -destination 'platform=iOS Simulator,name=iPhone 16' test | xcpretty

