//
//  InsightCard.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/24/25.
//

import SwiftUI

// MARK: - Insight Card Component
struct InsightCard: View {
    let insight: FocusInsight
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(insight.title)
                        .font(AppFonts.subheadline())
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    // Trend indicator
                    trendIndicator
                    
                    // Impact score
                    Text("\(Int(insight.impactScore))")
                        .font(AppFonts.caption())
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(impactColor)
                        )
                }
                
                // Message
                Text(insight.message)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Data confidence
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                    
                    Text("Based on \(insight.dataPoints) tasks")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                }
            }
            .padding(16)
            
            // Expandable recommendation section
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Recommendation")
                                .font(AppFonts.subheadline())
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        Text(insight.recommendation)
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button("Apply This Week") {
                                // TODO: Implement apply recommendation
                            }
                            .font(AppFonts.caption())
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppColors.accent)
                            .cornerRadius(16)
                            
                            Button("Remind Me Later") {
                                // TODO: Implement reminder
                            }
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.accent, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
    }
    
    private var trendIndicator: some View {
        Image(systemName: trendIcon)
            .font(.system(size: 14))
            .foregroundColor(trendColor)
    }
    
    private var trendIcon: String {
        switch insight.trend {
        case .improving: return "arrow.up.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .needsImprovement: return "exclamationmark.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch insight.trend {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .blue
        case .needsImprovement: return .orange
        }
    }
    
    private var impactColor: Color {
        if insight.impactScore >= 80 {
            return .red
        } else if insight.impactScore >= 60 {
            return .orange
        } else {
            return .blue
        }
    }
}
#Preview {
    InsightCard(insight: FocusInsight(type: InsightType.breakPattern, title: "Title", message: "Message", recommendation: "Recommendation", impactScore: 0, dataPoints: 90, trend: .stable))
}
