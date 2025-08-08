//
//  SubscriptionManager.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import Foundation
import StoreKit
import SwiftUI

// MARK: - Subscription Manager
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var currentSubscription: Product.SubscriptionInfo.Status?
    @Published var availableProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Product IDs - These need to match App Store Connect
    private let productIDs = [
        "focuszone_pro_monthly" // $2.99/month with 7-day free trial
    ]
    
    private var updateListenerTask: _Concurrency.Task<Void, Error>?
    private var transactionListener: _Concurrency.Task<Void, Error>?
    
    init() {
        // Start listening for transaction updates
        transactionListener = listenForTransactions()
        
        // Load products and check subscription status
        _Concurrency.Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
        transactionListener?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: productIDs)
            availableProducts = storeProducts
            print("✅ Loaded \(storeProducts.count) products")
            
            for product in storeProducts {
                print("📦 Product: \(product.displayName) - \(product.displayPrice)")
            }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("❌ Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async {
        var validSubscription: Product.SubscriptionInfo.Status?
        
        // Check for valid subscriptions
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                // Check if this is our subscription product
                if productIDs.contains(transaction.productID) {
                    if let subscription = try? await Product.products(for: [transaction.productID]).first?.subscription {
                        let status = try? await subscription.status.first
                        validSubscription = status
                        break
                    }
                }
            }
        }
        
        currentSubscription = validSubscription
        
        // Update subscription status
        if let subscription = validSubscription {
            switch subscription.state {
            case .subscribed:
                subscriptionStatus = .active
            case .expired, .revoked:
                subscriptionStatus = .expired
            case .inBillingRetryPeriod, .inGracePeriod:
                subscriptionStatus = .active // Still considered active
            default:
                subscriptionStatus = .inactive
            }
            
            print("🔄 Subscription status: \(subscriptionStatus)")
        } else {
            subscriptionStatus = .inactive
            print("🔄 No active subscription found")
        }
    }
    
    // MARK: - Purchase Flow
    
    func purchaseSubscription() async -> Bool {
        guard let product = availableProducts.first else {
            errorMessage = "Product not available"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                if case .verified(let transaction) = verificationResult {
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    
                    // Track purchase event
                    print("✅ Purchase successful: \(transaction.productID)")
                    return true
                }
                
            case .userCancelled:
                print("🚫 User cancelled purchase")
                
            case .pending:
                print("⏳ Purchase pending")
                
            @unknown default:
                print("❓ Unknown purchase result")
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("❌ Purchase failed: \(error)")
        }
        
        isLoading = false
        return false
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            
            if subscriptionStatus == .active {
                print("✅ Purchases restored successfully")
                isLoading = false
                return true
            } else {
                errorMessage = "No active subscription found"
            }
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            print("❌ Failed to restore purchases: \(error)")
        }
        
        isLoading = false
        return false
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> _Concurrency.Task<Void, Error> {
        return _Concurrency.Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    print("🔄 Transaction update: \(transaction.productID)")
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }
        }
    }
    
    // MARK: - Pro Features Check
    
    var isProUser: Bool {
        return subscriptionStatus == .active
    }
    
    var hasActiveSubscription: Bool {
        return subscriptionStatus == .active
    }
    
    var isInFreeTrial: Bool {
        guard let subscription = currentSubscription else { return false }
        
        // Check if user is in free trial period
        if case .verified(let renewalInfo) = subscription.renewalInfo {
            return renewalInfo.willAutoRenew && subscription.state == .subscribed
        }
        
        return false
    }
    
    // MARK: - Subscription Info
    
    var subscriptionExpiryDate: Date? {
        guard let subscription = currentSubscription,
              case .verified(let transaction) = subscription.transaction else {
            return nil
        }
        
        return transaction.expirationDate
    }
    
    var nextBillingDate: Date? {
        guard let subscription = currentSubscription,
              case .verified(let transaction) = subscription.transaction else {
            return nil
        }
        
        return transaction.expirationDate
    }
}

// MARK: - Supporting Types

enum SubscriptionStatus: String, CaseIterable {
    case unknown = "unknown"
    case inactive = "inactive"
    case active = "active"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .unknown: return "Checking..."
        case .inactive: return "Free"
        case .active: return "Pro"
        case .expired: return "Expired"
        }
    }
    
    var isPro: Bool {
        return self == .active
    }
}

// MARK: - Pro Features Definition

struct ProFeatures {
    static let maxTasksForFree = 10
    static let maxFocusSessionsForFree = 5
    static let maxInsightsForFree = 3
    
    static let proFeaturesList = [
        "Unlimited tasks and projects",
        "Advanced focus analytics",
        "Custom focus modes",
        "Smart break suggestions",
        "Advanced insights & recommendations",
    ]
}
