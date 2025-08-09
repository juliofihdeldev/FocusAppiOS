//
//  SubscriptionManager.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import Foundation
import StoreKit
import SwiftUI
import RevenueCat

// MARK: - Subscription Manager
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var currentSubscription: Product.SubscriptionInfo.Status?
    @Published var availableProducts: [StoreProduct] = [] // From RevenueCat packages for UI
    @Published var availablePackages: [Package] = [] // RevenueCat packages
    @Published var currentOffering: Offering?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // RevenueCat entitlement identifier (configure this in the RC dashboard)
    private let entitlementIdentifier = "pro" // TODO: Replace with your entitlement ID if different
    
    private var updateListenerTask: _Concurrency.Task<Void, Error>?
    private var transactionListener: _Concurrency.Task<Void, Error>?
    
    init() {
        // Load offerings and check status
        _Concurrency.Task {
            await loadOfferings()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
        transactionListener?.cancel()
    }
    
    // MARK: - Offerings / Products (RevenueCat)

    func loadOfferings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            let packages = offerings.current?.availablePackages ?? []
            availablePackages = packages
            availableProducts = packages.map { $0.storeProduct }
            print("✅ Loaded RevenueCat offerings: packages=\(packages.count)")
        } catch {
            errorMessage = "Failed to load offerings: \(error.localizedDescription)"
            print("❌ Failed to load offerings: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            let isActive = info.entitlements[entitlementIdentifier]?.isActive == true
            subscriptionStatus = isActive ? .active : .inactive
            print("🔄 RC Entitlement(\(entitlementIdentifier)) active=\(isActive)")
        } catch {
            subscriptionStatus = .unknown
            print("❌ Failed to fetch customerInfo: \(error)")
        }
    }
    
    // MARK: - Purchase Flow
    
    func purchaseSubscription() async -> Bool {
        guard let package = availablePackages.first else {
            errorMessage = "No package available"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            let info = result.customerInfo
            let isActive = info.entitlements[entitlementIdentifier]?.isActive == true
            if isActive {
                print("✅ RC purchase successful: \(package.storeProduct.productIdentifier)")
                await updateSubscriptionStatus()
                isLoading = false
                return true
            } else if result.userCancelled {
                print("🚫 User cancelled purchase")
            } else {
                print("❓ Purchase completed but entitlement inactive")
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("❌ RC purchase failed: \(error)")
        }
        
        isLoading = false
        return false
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let info = try await Purchases.shared.restorePurchases()
            let isActive = info.entitlements[entitlementIdentifier]?.isActive == true
            subscriptionStatus = isActive ? .active : .inactive
            print("🔁 RC restore completed, entitlement active=\(isActive)")
            isLoading = false
            return isActive
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            print("❌ RC restore failed: \(error)")
        }
        
        isLoading = false
        return false
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
