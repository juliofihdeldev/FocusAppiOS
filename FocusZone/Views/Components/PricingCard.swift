//
//  PricingCard.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/27/25.
//

import SwiftUI
import StoreKit

struct PricingCard: View {
    let product: Product
    
    var body: some View {
        VStack(spacing: 16) {
            // Badge
            Text("BEST VALUE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(.orange.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(.orange, lineWidth: 1)
                        )
                )
            
            // Price
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("/month")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text("7-day free trial")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
            
            // Description
            Text("Full access to all Pro features")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

struct PricingCardPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("BEST VALUE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(.orange.opacity(0.2))
                )
            
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$2.99")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("/month")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text("7-day free trial")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
            
            Text("Full access to all Pro features")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    VStack(spacing: 20) {
        PricingCardPlaceholder()
        
        // Note: PricingCard requires a Product, so we can't preview it directly
        // in a simple preview without StoreKit setup
    }
    .background(Color.black)
}
