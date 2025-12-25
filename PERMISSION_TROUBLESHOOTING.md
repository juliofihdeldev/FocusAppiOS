# 🔧 Permission Troubleshooting Guide

## Quick Fix Steps

### Step 1: Check Current Permissions

1. Open the app → **"Permissions"** tab (5th tab)
2. Tap **"Check All Permissions"**
3. Look at the debug information to see what's missing

### Step 2: Request Permissions

1. In the **"Permissions"** tab
2. Tap **"Request All Permissions"**
3. Allow notifications when prompted
4. Allow AlarmKit permissions when prompted

### Step 3: Manual iOS Settings (if needed)

1. Tap **"Open iOS Settings"** in the Permissions tab
2. Go to **FocusZone** → **Notifications**
3. Enable **"Allow Notifications"**
4. Enable **"Sounds"** and **"Badges"**

### Step 4: Test Again

1. Go to **"Alarm Test"** tab
2. Try scheduling a test alarm
3. Check console output for success messages

## Common Issues & Solutions

### ❌ "Notification permissions not granted"

**Solution:**

-   Go to iOS Settings → FocusZone → Notifications
-   Enable "Allow Notifications"
-   Enable "Sounds" and "Badges"

### ❌ "AlarmKit not supported"

**Solution:**

-   This is normal on iOS < 18
-   App will use fallback notifications instead
-   Update to iOS 18+ for full AlarmKit features

### ❌ "AlarmKit not authorized"

**Solution:**

-   Use "Request All Permissions" button
-   Or go to iOS Settings → FocusZone → Allow Notifications

### ❌ No notification received

**Solution:**

1. Check iOS Settings → FocusZone → Notifications
2. Make sure "Allow Notifications" is ON
3. Check "Sounds" and "Badges" are enabled
4. Try the "Test Notification" button in Permissions tab

## Debug Information

### What to Look For:

-   **📱 Notification Status: 3** = Authorized ✅
-   **📱 Notification Status: 0** = Not Determined ⚠️
-   **📱 Notification Status: 1** = Denied ❌
-   **🔔 AlarmKit Support: true** = Supported ✅
-   **🔔 AlarmKit Authorized: true** = Authorized ✅

### Console Messages:

-   **✅ Fallback notification scheduled** = Success!
-   **❌ Notification permissions not granted** = Need to enable notifications
-   **📱 Using fallback notification** = Working with regular notifications

## Testing Steps

### Quick Test:

1. Permissions tab → "Test Notification"
2. Should receive notification in 2 seconds

### Alarm Test:

1. Alarm Test tab → Set time → "Schedule Test Alarm"
2. Should see success message
3. Wait for alarm time
4. Should receive notification

### Debug Test:

1. Permissions tab → "Check All Permissions"
2. Look for any ❌ or ⚠️ indicators
3. Fix any issues found

## Still Having Issues?

1. **Restart the app** completely
2. **Check iOS version** (need iOS 18+ for AlarmKit)
3. **Reset notification permissions** in iOS Settings
4. **Check Focus/Do Not Disturb** settings
5. **Try on a different device** if available

The Permissions tab will show you exactly what's wrong and help you fix it!
