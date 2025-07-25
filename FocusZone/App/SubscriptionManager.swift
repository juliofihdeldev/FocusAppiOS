//
//  SubscriptionManager.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/24/25.
//

import Foundation

// MARK: - Subscription Manager
class SubscriptionManager: ObservableObject {
    @Published var isSubscribed = false
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    
    enum SubscriptionStatus {
        case notSubscribed
        case freeTrial
        case subscribed
        case trialExpired
    }
    
    func checkSubscriptionStatus() {
        // TODO: Implement actual subscription checking logic
        // For now, simulate based on user defaults
        isSubscribed = UserDefaults.standard.bool(forKey: "isProSubscribed")
    }
    
    func startFreeTrial() {
        // TODO: Implement trial logic
        UserDefaults.standard.set(true, forKey: "isProSubscribed")
        isSubscribed = true
        subscriptionStatus = .freeTrial
    }
    
    func subscribe() {
        // TODO: Implement actual subscription logic
        UserDefaults.standard.set(true, forKey: "isProSubscribed")
        isSubscribed = true
        subscriptionStatus = .subscribed
    }
}
