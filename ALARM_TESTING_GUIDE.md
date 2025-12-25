# Alarm Testing Guide

## Overview

I've added comprehensive alarm testing functionality to help you verify that the AlarmKit integration is working correctly.

## How to Test Alarms

### Method 1: Quick Test Button (Timeline View)

-   Open the app and go to the Timeline tab
-   Look for the orange floating alarm button in the bottom-right corner
-   Tap it to schedule a test alarm that will trigger in 5 seconds
-   Check if you receive a notification

### Method 2: Full Test Interface (Alarm Test Tab)

-   Open the app and go to the "Alarm Test" tab (4th tab)
-   This provides a comprehensive testing interface with:
    -   **Status indicators** showing AlarmKit support and authorization
    -   **Time picker** to set when you want the test alarm to trigger
    -   **Schedule Test Alarm** button to create a test alarm
    -   **Request Permissions** button to grant AlarmKit permissions
    -   **Debug Notifications** button to see pending notifications in console

## What to Expect

### When AlarmKit is Supported (iOS 18+):

-   Alarms will be scheduled using AlarmKit
-   You'll get native iOS alarm notifications
-   Live Activities will start automatically when alarms fire

### When AlarmKit is Not Supported (iOS < 18):

-   Fallback to regular push notifications
-   Notifications will still work but without AlarmKit features

## Debugging

### Check Console Output

-   Look for messages starting with:
    -   `🚨` - Alarm triggered
    -   `📱` - Notification scheduling
    -   `✅` - Success messages
    -   `❌` - Error messages

### Use Debug Notifications Button

-   Tap "Debug Notifications" in the Alarm Test tab
-   Check the console for detailed information about pending notifications

## Troubleshooting

### No Alarm Received?

1. Check if notifications are enabled in iOS Settings
2. Verify AlarmKit permissions are granted
3. Use the "Debug Notifications" button to see pending notifications
4. Check console output for error messages

### AlarmKit Not Supported?

-   This is normal on iOS versions below 18.0
-   The app will automatically use fallback notifications
-   Update to iOS 18+ for full AlarmKit functionality

## Test Scenarios

### Quick Test (5 seconds)

-   Use the floating button in Timeline view
-   Perfect for quick verification

### Custom Time Test

-   Use the Alarm Test tab
-   Set a specific time (e.g., 1 minute from now)
-   Good for testing specific scenarios

### Permission Test

-   Use "Request Permissions" button
-   Verify that permissions are granted correctly

## Expected Behavior

1. **Alarm Scheduled**: You should see success messages in console
2. **Alarm Triggered**: You should receive a notification with task details
3. **Live Activity**: Should start automatically (if supported)
4. **Task Status**: Should update to "in progress"

## Console Messages to Look For

```
✅ Fallback notification scheduled for 'Test Task' at 2024-01-01 10:00:00
🚨 Alarm triggered for task: Test Task
📱 Pending notifications: 1
```

This testing setup will help you verify that the alarm functionality is working correctly in your app!
