//
//  PaywallView.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var showingRestoreAlert = false
    @State private var isPurchasing = false
    @State private var showPaywall = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.8),
                        Color.blue.opacity(0.6),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        // Header
                        VStack(spacing: 16) {
                            // App icon
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 60, weight: .light))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            
                            VStack(spacing: 8) {
                                Text("Unlock FocusZin+ Pro")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Supercharge your productivity")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Features showcase
                        VStack(spacing: 24) {
                            ForEach(Array(ProFeatures.proFeaturesList.enumerated()), id: \.offset) { index, feature in
                                FeatureRow(
                                    icon: getFeatureIcon(for: index),
                                    title: feature,
                                    delay: Double(index) * 0.1,
                                    description: "Pro feature"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Pricing card
                        VStack(spacing: 20) {
                            if let product = subscriptionManager.availableProducts.first {
                                PricingCard(product: product)
                                
                            } else {
                                PricingCardPlaceholder()
                            }
                            
                            // CTA Button
                            Button(action: {
                                _Concurrency.Task {
                                    print("Try to Purchasing subscription")
                                    isPurchasing = true
                                    let success = await subscriptionManager.purchaseSubscription()
                                    isPurchasing = false
                                    
                                    if success {
                                        dismiss()
                                    }
                                }
                            }) {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "crown.fill")
                                            .font(.title3)
                                    }
                                    
                                    Text(isPurchasing ? "Processing..." : "Start Free Trial")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
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
                                .cornerRadius(16)
                                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(isPurchasing || subscriptionManager.isLoading)
                            .padding(.horizontal, 20)
                        }
                        
                        // Footer actions
                        VStack(spacing: 16) {
                            HStack(spacing: 20) {
                                Button("Restore Purchases") {
                                    _Concurrency.Task {
                                        let success = await subscriptionManager.restorePurchases()
                                        showingRestoreAlert = true
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                
                                Button("Privacy Policy") {
                                    // TODO: Open privacy policy
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                
                                Button("Terms of Use") {
                                    // TODO: Open terms of use
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Text("7-day free trial, then $2.99/month. Cancel anytime.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK") { }
        } message: {
            if subscriptionManager.subscriptionStatus == .active {
                Text("Your subscription has been restored successfully!")
            } else {
                Text("No active subscription found. If you believe this is an error, please contact support.")
            }
        }
        .onAppear {
            _Concurrency.Task {
                await subscriptionManager.loadProducts()
            }
        }
    }
    
    private func getFeatureIcon(for index: Int) -> String {
        let icons = [
            "infinity.circle.fill",
            "chart.line.uptrend.xyaxis",
            "brain.head.profile",
            "lightbulb.fill",
            "magnifyingglass.circle.fill",
            "doc.text.fill",
            "paintbrush.fill",
            "icloud.fill",
            "headphones.circle.fill"
        ]
        return icons[safe: index] ?? "star.fill"
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    PaywallView()
}
