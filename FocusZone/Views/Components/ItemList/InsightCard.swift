//
//  InsightCard.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/24/25.
//

import SwiftUI

struct InsightCard: View {
    let insight: FocusInsight
    @State private var isExpanded = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced main content
            VStack(alignment: .leading, spacing: 16) {
                // Enhanced header with better visual hierarchy
                HStack(alignment: .top, spacing: 12) {
                    // Icon container with background
                    ZStack {
                        Circle()
                            .fill(trendColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: trendIcon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(trendColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(AppFonts.headline())
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        // Category badge
                        Text(insight.type.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(trendColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(trendColor.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(trendColor.opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                    }
                    
                    Spacer()
                    
                    // Enhanced impact score with gradient
                    VStack(spacing: 2) {
                        Text("\(Int(insight.impactScore))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(NSLocalizedString("impact", comment: "Impact score label"))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                impactColor,
                                impactColor.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: impactColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                
                // Enhanced message with better typography
                Text(insight.message)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Enhanced data confidence with visual improvements
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(trendColor.opacity(0.7))
                        
                        Text(String(format: NSLocalizedString("based_on_tasks", comment: "Based on number of tasks"), insight.dataPoints))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Expand indicator
                    HStack(spacing: 4) {
                        Text(isExpanded ? NSLocalizedString("collapse", comment: "Collapse button") : NSLocalizedString("view_details", comment: "View details button"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(trendColor)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(trendColor)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(trendColor.opacity(0.1))
                    )
                }
            }
            .padding(16)
            
            // Enhanced expandable recommendation section
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Elegant divider
                    HStack {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    trendColor.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Enhanced recommendation header
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.2))
                                    .frame(width: 28, height: 28)
                                
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.yellow)
                            }
                            
                            Text(NSLocalizedString("recommendation", comment: "Recommendation section title"))
                                .font(AppFonts.subheadline())
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                        }
                        
                        // Enhanced recommendation text
                        Text(insight.recommendation)
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(trendColor.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(trendColor.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        
                        // Enhanced action buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                // TODO: Implement add to reminders
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12, weight: .medium))
                                    Text(NSLocalizedString("add_to_reminders", comment: "Add to reminders button"))
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            trendColor,
                                            trendColor.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(18)
                                .shadow(color: trendColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(trendColor.opacity(0.1), lineWidth: 1)
                )
                .shadow(
                    color: isPressed ? trendColor.opacity(0.2) : .black.opacity(0.05),
                    radius: isPressed ? 12 : 8,
                    x: 0,
                    y: isPressed ? 6 : 2
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                isExpanded.toggle()
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
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

// MARK: - Extensions
extension InsightType {
    var displayName: String {
        switch self {
        case .timeOfDay:
            return NSLocalizedString("time_pattern", comment: "Time Pattern insight type")
        case .taskDuration:
            return NSLocalizedString("duration", comment: "Duration insight type")
        case .breakPattern:
            return NSLocalizedString("break_time", comment: "Break Time insight type")
        case .completion:
            return NSLocalizedString("completion", comment: "Completion insight type")
        case .dayOfWeek:
            return NSLocalizedString("weekly_pattern", comment: "Weekly Pattern insight type")
        }
    }
}
#Preview {
    InsightCard(insight: FocusInsight(type: InsightType.breakPattern, title: "Title", message: "Message", recommendation: "Recommendation", impactScore: 0, dataPoints: 90, trend: .stable))
}
