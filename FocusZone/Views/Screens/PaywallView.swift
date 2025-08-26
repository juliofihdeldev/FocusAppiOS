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
    @State private var selectedProduct: Product?
    
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
                        VStack(spacing: 12) {
//                             App icon
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
                                Text("Unlock FocusZen+ Pro")
                                    .font(AppFonts.title())
                                    .foregroundColor(.white)
                                
                                Text("Supercharge your productivity")
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Features showcase
                        VStack(spacing: 12) {
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
                        
                        // Product selection
                        VStack(spacing: 20) {
                            if subscriptionManager.isLoading {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                    
                                    Text("Loading subscription options...")
                                        .font(AppFonts.subheadline())
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.vertical, 40)
                            } else if !subscriptionManager.availableProducts.isEmpty {
                                VStack(spacing: 16) {
                                    Text("Choose Your Plan")
                                        .font(AppFonts.title())
                                        .foregroundColor(.white)
                                    
                                    ForEach(subscriptionManager.availableProducts, id: \.id) { product in
                                        ProductSelectionCard(
                                            product: product,
                                            isSelected: selectedProduct?.id == product.id,
                                            onTap: {
                                                selectedProduct = product
                                            }
                                        )
                                    }
                                }
                                
                                // CTA Button
                                Button(action: {
                                    guard let product = selectedProduct else { return }
                                    _Concurrency.Task {
                                        print("Try to Purchasing subscription: \(product.id)")
                                        isPurchasing = true
                                        let success = await subscriptionManager.purchaseProduct(product)
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
                                        
                                        Text(isPurchasing ? "Processing..." : getCTAButtonText())
                                            .font(AppFonts.headline())
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
                                .disabled(isPurchasing || subscriptionManager.isLoading || selectedProduct == nil)
                                .padding(.horizontal, 20)
                            } else if let errorMessage = subscriptionManager.errorMessage {
                                VStack(spacing: 16) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.orange)
                                    
                                    Text("Unable to load subscription options")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(errorMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                    
                                    Button("Retry") {
                                        _Concurrency.Task {
                                            await subscriptionManager.loadProducts()
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.orange)
                                    .cornerRadius(8)
                                }
                                .padding(.vertical, 40)
                            } else {
                                PricingCardPlaceholder()
                            }
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
                            
                            VStack(spacing: 8) {
                                Text("7-day free trial, then \(getFooterText())")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                
                                if let product = selectedProduct, product.id.contains("annual") {
                                    Text("Billed annually • Cancel anytime")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text("Billed monthly • Cancel anytime")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                        .multilineTextAlignment(.center)
                                }
                            }
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
                // Auto-select the best value product (annual plan) if available
                if selectedProduct == nil && !subscriptionManager.availableProducts.isEmpty {
                    selectedProduct = subscriptionManager.bestValueProduct ?? subscriptionManager.availableProducts.first
                }
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
    
    private func getFooterText() -> String {
        guard let product = selectedProduct else {
            return "$2.99/month. Cancel anytime."
        }
        
        if product.id.contains("focus_zen_plus_pro_best_value") {
            return "Save with yearly billing. Cancel anytime."
        } else if product.id.contains("month") {
            return "$2.99/month. Cancel anytime."
        } else {
            return "$2.99/month. Cancel anytime."
        }
    }
    
    private func getCTAButtonText() -> String {
        guard let product = selectedProduct else {
            return "Start Free Trial"
        }
        
        if product.id.contains("annual") {
            return "Start Free Trial"
        } else if product.id.contains("month") {
            return "Start Free Trial"
        } else {
            return "Start Free Trial"
        }
    }
}



extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    PaywallView()
}
