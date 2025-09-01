//
//  FocusInsightsView.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/24/25.
//

import SwiftUI
import SwiftData

struct FocusInsightsView: View {
    @StateObject private var analyticsEngine = FocusAnalyticsEngine()
    @Environment(\.modelContext) private var modelContext
    @State private var showingUpgradeSheet = false

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    if analyticsEngine.isAnalyzing {
                        loadingView
                    } else if analyticsEngine.weeklyInsights.isEmpty {
                        emptyStateView
                    } else {
                        // Insights Cards
                        LazyVStack(spacing: 16) {
                            ForEach(analyticsEngine.weeklyInsights) { insight in
                                InsightCard(insight: insight)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action buttons
                        actionButtonsSection
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(NSLocalizedString("focus_coach", comment: "Focus Coach navigation title"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupAnalytics()
            }
            .refreshable {
                await analyticsEngine.generateWeeklyInsights()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.accent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("your_focus_coach", comment: "Your Focus Coach header title"))
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text(NSLocalizedString("ai_powered_insights", comment: "AI-powered insights subtitle"))
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Weekly summary
            if !analyticsEngine.weeklyInsights.isEmpty {
                weeklySummaryCard
            }
        }
    }
    
    private var weeklySummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(NSLocalizedString("this_weeks_insights", comment: "This Week's Insights section title"))
                    .font(AppFonts.subheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text(String(format: NSLocalizedString("insights_count", comment: "Number of insights"), analyticsEngine.weeklyInsights.count))
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
            
            HStack(spacing: 16) {
                ForEach(InsightType.allCases.prefix(3), id: \.self) { type in
                    let count = analyticsEngine.weeklyInsights.filter { $0.type == type }.count
                    
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(AppFonts.headline())
                            .fontWeight(.bold)
                            .foregroundColor(colorForInsightType(type))
                        
                        Text(type.displayName)
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppColors.accent)
            
            Text(NSLocalizedString("analyzing_focus_patterns", comment: "Analyzing focus patterns loading text"))
                .font(AppFonts.body())
                .foregroundColor(AppColors.textSecondary)
            
            Text(NSLocalizedString("this_may_take_moment", comment: "Loading may take a moment text"))
                .font(AppFonts.caption())
                .foregroundColor(AppColors.textSecondary.opacity(0.7))
        }
        .padding(.top, 40)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(NSLocalizedString("not_enough_data_yet", comment: "Not enough data yet title"))
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textSecondary)
                
                Text(NSLocalizedString("complete_tasks_for_insights", comment: "Complete tasks to unlock insights message"))
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textSecondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(NSLocalizedString("view_sample_insights", comment: "View Sample Insights button")) {
                // Show sample insights for demonstration
                showSampleInsights()
            }
            .font(AppFonts.body())
            .foregroundColor(AppColors.accent)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppColors.accent, lineWidth: 1)
            )
        }
        .padding(.top, 60)
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
               _Concurrency.Task {
                    await analyticsEngine.generateWeeklyInsights()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text(NSLocalizedString("refresh_insights", comment: "Refresh Insights button"))
                }
                .font(AppFonts.body())
                .foregroundColor(AppColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.accent, lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)

            
            Button(NSLocalizedString("upgrade_advanced_insights", comment: "Upgrade for Advanced Insights button")) {
                showingUpgradeSheet = true
            }
            .font(AppFonts.caption())
            .foregroundColor(AppColors.textSecondary)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Helper Methods
    private func setupAnalytics() {
        analyticsEngine.setModelContext(modelContext)
        _Concurrency.Task {
            await analyticsEngine.generateWeeklyInsights()
        }
    }

    // Helper to avoid generic env wrapper in stored context
    private func modelContextOptional() -> ModelContext? { modelContext }
    
    private func currentWeekRange() -> DateInterval {
        let cal = Calendar.current
        let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let end = cal.date(byAdding: .day, value: 7, to: start) ?? start
        return DateInterval(start: start, end: end)
    }
    
    private func showSampleInsights() {
        // Add sample insights for demonstration
        analyticsEngine.weeklyInsights = [
            FocusInsight(
                type: .timeOfDay,
                title: NSLocalizedString("peak_performance_window", comment: "Peak Performance Window insight title"),
                message: String(format: NSLocalizedString("productive_early_morning", comment: "Productive during early morning message"), 40),
                recommendation: NSLocalizedString("schedule_important_tasks_early", comment: "Schedule important tasks early recommendation"),
                impactScore: 85,
                dataPoints: 12,
                trend: .improving
            ),
            FocusInsight(
                type: .breakPattern,
                title: NSLocalizedString("break_power_boost", comment: "Break Power Boost insight title"),
                message: String(format: NSLocalizedString("tasks_after_breaks_higher", comment: "Tasks after breaks have higher completion rates"), 25),
                recommendation: NSLocalizedString("schedule_breaks_before_tasks", comment: "Schedule breaks before important tasks recommendation"),
                impactScore: 75,
                dataPoints: 8,
                trend: .improving
            )
        ]
    }
    
    private func colorForInsightType(_ type: InsightType) -> Color {
        switch type {
        case .timeOfDay: return .orange
        case .taskDuration: return .blue
        case .breakPattern: return .green
        case .completion: return .purple
        case .dayOfWeek: return .pink
        }
    }
}


