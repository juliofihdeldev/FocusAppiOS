//
//  UpgradeToProSheet.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/24/25.
//

import SwiftUI

// MARK: - Upgrade Sheet
struct UpgradeToProSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        VStack(spacing: 8) {
                            Text("Unlock AI Focus Coach")
                                .font(AppFonts.title())
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Get personalized insights to 3x your productivity")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Features
                    VStack(spacing: 20) {
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Smart Analytics",
                            description: "Discover your peak performance hours and patterns"
                        )
                        
                        FeatureRow(
                            icon: "lightbulb.fill",
                            title: "Weekly Insights",
                            description: "Get 5+ personalized recommendations every week"
                        )
                        
                        FeatureRow(
                            icon: "target",
                            title: "Goal Optimization",
                            description: "AI-powered suggestions to hit your focus targets"
                        )
                        
                        FeatureRow(
                            icon: "brain.head.profile",
                            title: "Burnout Prevention",
                            description: "Early warnings when you're overloading yourself"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Pricing
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("$3.00")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("per month")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Button("Start 7-Day Free Trial") {
                            // TODO: Implement purchase flow
                            
                            
                        }
                        .font(AppFonts.headline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        
                        Text("Cancel anytime • No commitment")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}


#Preview {
    UpgradeToProSheet()
}
