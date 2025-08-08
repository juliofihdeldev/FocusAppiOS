# FocusZone Pro Subscription Setup Guide

## 🎯 Implementation Status

✅ **COMPLETED:**

-   SubscriptionManager with StoreKit 2 integration
-   PaywallView with beautiful UI design
-   ProFeatureGate component for feature restrictions
-   Settings integration with subscription management
-   UpgradeToProSheet integration

⏳ **REMAINING STEPS:**

## 1. App Store Connect Configuration

### Create Subscription Product

1. Open [App Store Connect](https://appstoreconnect.apple.com)
2. Go to your FocusZone app
3. Navigate to **Features** → **In-App Purchases**
4. Click **+** to create new subscription
5. Select **Auto-Renewable Subscription**

### Subscription Details

```
Product ID: focuszone_pro_monthly
Reference Name: FocusZone Pro Monthly
Subscription Group: FocusZone Pro (create new group)

Pricing:
- Territory: United States
- Price: $2.99 USD
- Free Trial: 7 days

Subscription Group Display Name: FocusZone Pro
```

### Localization

Add localizations for:

-   **Display Name**: "FocusZone Pro"
-   **Description**: "Unlock unlimited tasks, advanced analytics, custom focus modes, and premium features with a 7-day free trial."

## 2. Xcode Project Configuration

### Add StoreKit Configuration File

1. In Xcode: File → New → File
2. Choose **StoreKit Configuration File**
3. Name it `Products.storekit`
4. Add subscription product:

```json
{
	"identifier": "focuszone_pro_monthly",
	"type": "auto-renewable",
	"displayName": "FocusZone Pro",
	"description": "Unlock all premium features",
	"price": 2.99,
	"familyShareable": false,
	"subscriptionDuration": "P1M",
	"introductoryOffer": {
		"type": "freeTrial",
		"duration": "P7D"
	}
}
```

### Update Info.plist

Add to `Info.plist`:

```xml
<key>SKAdNetworkItems</key>
<array>
    <!-- Add any ad network IDs if using analytics -->
</array>
```

## 3. Pro Feature Integration Examples

### Example: Limit Tasks for Free Users

```swift
// In TaskFormView or TaskViewModel
@StateObject private var subscriptionManager = SubscriptionManager.shared

func canCreateNewTask() -> Bool {
    if subscriptionManager.isProUser {
        return true
    }

    // Check if user has reached free limit
    let taskCount = /* get current task count */
    return taskCount < ProFeatures.maxTasksForFree
}

// Show paywall when limit reached
if !canCreateNewTask() {
    // Present PaywallView
}
```

### Example: Gate Advanced Analytics

```swift
// In FocusInsightsView
ProFeatureGate(feature: .advancedAnalytics) {
    AdvancedAnalyticsView()
}
```

### Example: Limit Focus Sessions

```swift
// In TaskTimer or FocusModeManager
func canStartFocusSession() -> Bool {
    if subscriptionManager.isProUser {
        return true
    }

    let todaysSessions = /* count today's focus sessions */
    return todaysSessions < ProFeatures.maxFocusSessionsForFree
}
```

## 4. Testing

### StoreKit Testing in Simulator

1. In Xcode scheme editor, set StoreKit Configuration to `Products.storekit`
2. Run app in simulator
3. Test purchase flow with StoreKit test data

### TestFlight Testing

1. Upload build to TestFlight
2. Enable StoreKit testing for external testers
3. Test on real devices with sandbox Apple IDs

### Sandbox Testing

Create sandbox test users in App Store Connect:

-   Test purchase flow
-   Test free trial
-   Test subscription renewal
-   Test restore purchases

## 5. Analytics & Monitoring

### Track Key Events

Add analytics for:

-   Paywall views
-   Purchase attempts
-   Successful purchases
-   Trial starts
-   Cancellations
-   Feature usage by tier

### Recommended Tools

-   RevenueCat (subscription analytics)
-   App Store Connect Analytics
-   Firebase Analytics
-   Custom analytics in your backend

## 6. Marketing & ASO

### App Store Listing

-   Highlight Pro features in screenshots
-   Add "In-App Purchases" to app description
-   Create compelling feature comparison

### In-App Marketing

-   Onboarding hints about Pro features
-   Smart paywall triggers (after positive actions)
-   Feature discovery moments

## 7. Legal Requirements

### Required Links

-   Privacy Policy (update for subscription data)
-   Terms of Service (subscription terms)
-   Subscription cancellation instructions

### Auto-Renewal Disclosure

Include in app description:
"Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period."

## 8. Launch Checklist

-   [ ] Subscription products configured in App Store Connect
-   [ ] StoreKit configuration file added to project
-   [ ] Free tier limitations implemented
-   [ ] Pro features properly gated
-   [ ] Paywall tested and polished
-   [ ] Analytics tracking implemented
-   [ ] Legal pages updated
-   [ ] TestFlight beta testing completed
-   [ ] App Store review guidelines compliance

## 🔧 Quick Integration Tips

### Add Pro Badge to Features

```swift
HStack {
    Text("Advanced Analytics")
    if !subscriptionManager.isProUser {
        ProBadge()
    }
}
```

### Smart Paywall Triggers

-   After completing 3rd task (show value)
-   When trying to create 11th task (hit limit)
-   After 7 days of usage (engagement proven)
-   When accessing premium features

### Restore Purchases

Always provide restore option for users who:

-   Reinstalled the app
-   Got a new device
-   Are having sync issues

## 📱 Ready for App Store Review

The subscription implementation follows Apple's guidelines:

-   Clear pricing display
-   Easy cancellation
-   Proper auto-renewal disclosure
-   Value-driven feature gating
-   Seamless free trial experience

## 🎉 Launch Strategy

1. **Soft Launch**: Release with basic restrictions
2. **Iterate**: Adjust based on conversion data
3. **Optimize**: A/B test paywall messaging
4. **Scale**: Add more premium features over time

---

**Next Steps:**

1. Complete App Store Connect setup
2. Test subscription flow thoroughly
3. Implement pro feature restrictions
4. Submit for App Store review

Good luck with your subscription launch! 🚀
