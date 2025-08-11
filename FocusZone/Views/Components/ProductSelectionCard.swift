import SwiftUI
import StoreKit

struct ProductSelectionCard: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection indicator
                Circle()
                    .fill(isSelected ? Color.orange : Color.white.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Text(product.displayName)
                                    .font(AppFonts.headline())
                                    .foregroundColor(.white)
                                
                                if product.id.contains("focus_zen_plus_pro_best_value") {
                                    Text("BEST VALUE")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(.orange.opacity(0.2))
                                                .overlay(
                                                    Capsule()
                                                        .stroke(.orange, lineWidth: 1)
                                                )
                                        )
                                }
                            }
                            
                            Text(getProductDescription(for: product))
                                .font(AppFonts.subheadline())
                                .foregroundColor(.white.opacity(0.7))
                            
                            if product.id.contains("focus_zen_plus_pro_best_value") {
                                let savings = SubscriptionManager.shared.calculateSavingsPercentage()
                                if let savingsPercentage = savings {
                                    Text("Save \(Int(round(savingsPercentage)))% vs monthly")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.green)
                                } else {
                                    Text("Save with best value plan")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.green)
                                }
                                
                                // Show monthly equivalent price
                                if let monthlyEquivalent = SubscriptionManager.shared.getMonthlyEquivalentPrice(for: product) {
                                    Text("\(monthlyEquivalent)/month when billed annually")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(product.displayPrice)
                                .font(AppFonts.title())
                                .foregroundColor(.white)
                            
                            Text(getBillingPeriod(for: product))
                                .font(AppFonts.caption())
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.orange.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.orange : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
    
    private func getProductDescription(for product: Product) -> String {
        if product.id.contains("focus_zen_plus_pro_best_value") {
            return "Best value plan - Save with yearly billing"
        } else if product.id.contains("month") {
            return "Monthly plan - Flexible monthly billing"
        } else {
            return "Pro subscription"
        }
    }
    
    private func getBillingPeriod(for product: Product) -> String {
        if product.id.contains("focus_zen_plus_pro_best_value") {
            return "/year"
        } else if product.id.contains("month") {
            return "/month"
        } else {
            return ""
        }
    }
}


