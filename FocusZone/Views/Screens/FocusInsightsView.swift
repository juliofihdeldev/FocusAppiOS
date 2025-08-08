//
//  FocusInsightsView.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/24/25.
//

import SwiftUI

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
            .navigationTitle("Focus Coach")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupAnalytics()
            }
            .refreshable {
                await analyticsEngine.generateWeeklyInsights()
            }
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            UpgradeToProSheet()
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
                    Text("Your Focus Coach")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text("AI-powered insights from your tasks")
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
                Text("This Week's Insights")
                    .font(AppFonts.subheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(analyticsEngine.weeklyInsights.count) insights")
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
            
            Text("Analyzing your focus patterns...")
                .font(AppFonts.body())
                .foregroundColor(AppColors.textSecondary)
            
            Text("This may take a moment")
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
                Text("Not enough data yet")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textSecondary)
                
                Text("Complete a few more tasks to unlock personalized insights")
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textSecondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button("View Sample Insights") {
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
                    Text("Refresh Insights")
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
            
            Button("Upgrade for Advanced Insights") {
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
    
    private func showSampleInsights() {
        // Add sample insights for demonstration
        analyticsEngine.weeklyInsights = [
            FocusInsight(
                type: .timeOfDay,
                title: "🌅 Peak Performance Window",
                message: "You're 40% more productive during early morning",
                recommendation: "Schedule your most important tasks between 6-9 AM",
                impactScore: 85,
                dataPoints: 12,
                trend: .improving
            ),
            FocusInsight(
                type: .breakPattern,
                title: "🧘 Break Power Boost",
                message: "Tasks after breaks have 25% higher completion rates",
                recommendation: "Schedule 5-10 minute breaks before important tasks",
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


