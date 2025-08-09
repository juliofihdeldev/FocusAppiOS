//
//  ProFeatureGate.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import SwiftUI

// MARK: - Pro Feature Gate
struct ProFeatureGate<Content: View>: View {
    let feature: ProFeature
    let content: () -> Content
    
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    
    var body: some View {
        Group {
            if subscriptionManager.isProUser {
                content()
            } else {
                ProFeatureLockedView(feature: feature) {
                    showPaywall = true
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Pro Feature Locked View
struct ProFeatureLockedView: View {
    let feature: ProFeature
    let onUpgradeAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.1),
                            Color.blue.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.3),
                                    Color.blue.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 1)
                    )
                
                VStack(spacing: 12) {
                    // Crown icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.yellow.opacity(0.2),
                                    Color.orange.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "crown.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                    }
                    
                    VStack(spacing: 4) {
                        Text(feature.title)
                            .font(AppFonts.headline())
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(feature.description)
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: onUpgradeAction) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.subheadline)
                            Text("Upgrade to Pro")
                                .font(AppFonts.subheadline())
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple,
                                    Color.blue
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(20)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Pro Badge Component
struct ProBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 10, weight: .bold))
            Text("PRO")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange,
                    Color.red
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(8)
    }
}

// MARK: - Pro Feature Definition
struct ProFeature {
    let title: String
    let description: String
    let icon: String
    
    static let unlimitedTasks = ProFeature(
        title: "Unlimited Tasks",
        description: "Create unlimited tasks and projects without restrictions",
        icon: "infinity"
    )
    
    static let advancedAnalytics = ProFeature(
        title: "Advanced Analytics",
        description: "Deep insights into your productivity patterns and trends",
        icon: "chart.line.uptrend.xyaxis"
    )
    
    static let customFocusModes = ProFeature(
        title: "Custom Focus Modes",
        description: "Create personalized focus modes tailored to your workflow",
        icon: "brain.head.profile"
    )
    
    static let smartBreaks = ProFeature(
        title: "Smart Break Suggestions",
        description: "AI-powered break recommendations based on your work patterns",
        icon: "lightbulb.fill"
    )
    
    static let detailedInsights = ProFeature(
        title: "Detailed Insights",
        description: "Comprehensive productivity reports and recommendations",
        icon: "magnifyingglass.circle.fill"
    )
    
    static let cloudSync = ProFeature(
        title: "Cloud Sync",
        description: "Sync your data across all your devices seamlessly",
        icon: "icloud.fill"
    )
    
    static let customThemes = ProFeature(
        title: "Custom Themes",
        description: "Personalize your app with beautiful themes and icons",
        icon: "paintbrush.fill"
    )
}

// MARK: - Subscription Status View
struct SubscriptionStatusView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(subscriptionManager.isProUser ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(subscriptionManager.subscriptionStatus.displayName)
                    .font(AppFonts.subheadline())
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                if subscriptionManager.isProUser {
                    if subscriptionManager.isInFreeTrial {
                        Text("Free trial active")
                            .font(AppFonts.caption())
                            .foregroundColor(.green)
                    } else if let nextBilling = subscriptionManager.nextBillingDate {
                        Text("Next billing: \(nextBilling, style: .date)")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                    }
                } else {
                    Text("Limited features")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            if !subscriptionManager.isProUser {
                Button("Upgrade") {
                    showPaywall = true
                }
                .font(AppFonts.caption())
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.card)
        .cornerRadius(12)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

#Preview("Pro Feature Gate") {
    ProFeatureGate(feature: .advancedAnalytics) {
        Text("Advanced Analytics Content")
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }
}

#Preview("Subscription Status") {
    SubscriptionStatusView()
        .padding()
}
