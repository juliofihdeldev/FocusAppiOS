//
//  FocusZoneWidgetLiveActivity.swift
//  FocusZoneWidget
//
//  Created by Julio J Fils on 7/20/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Define the attributes for the widget extension
struct FocusZoneWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var taskTitle: String
        var taskDescription: String?
        var startTime: Date
        var endTime: Date
        var isActive: Bool
        var timeRemaining: TimeInterval
        var progress: Double
        var currentPhase: FocusPhase
        var totalSessions: Int
        var completedSessions: Int
    }

    var taskId: String
    var taskType: String
    var focusMode: String
    var sessionDuration: TimeInterval
    var breakDuration: TimeInterval?
}

// FocusPhase is defined in the main app, but we need to define it here for the widget extension
enum FocusPhase: String, CaseIterable, Codable {
    case focus = "focus"
    case shortBreak = "short_break"
    case longBreak = "long_break"
    case completed = "completed"
    case paused = "paused"
    
    var displayName: String {
        switch self {
        case .focus:
            return "Focus"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        case .completed:
            return "Completed"
        case .paused:
            return "Paused"
        }
    }
    
    var icon: String {
        switch self {
        case .focus:
            return "brain.head.profile"
        case .shortBreak:
            return "cup.and.saucer"
        case .longBreak:
            return "bed.double"
        case .completed:
            return "checkmark.circle.fill"
        case .paused:
            return "pause.circle.fill"
        }
    }
}

struct FocusZoneWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusZoneWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            FocusLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: context.state.currentPhase.icon)
                                .font(.title3)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 1)
                            
                            Text(context.state.currentPhase.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.9))
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                        
                        Text("\(Int(context.state.progress * 100))%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(formatTimeRemaining(context.state.timeRemaining))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1)
                        
                        Text("remaining")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 10) {
                        Text(context.state.taskTitle)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.3), radius: 1)
                        
                        // Enhanced progress bar
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white,
                                            Color.white.opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, 200 * context.state.progress), height: 6)
                                .animation(.easeInOut(duration: 0.3), value: context.state.progress)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 6, height: 6)
                            
                            Text("Session \(context.state.completedSessions + 1) of \(context.state.totalSessions)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(context.state.isActive ? Color.green : Color.orange)
                                .frame(width: 6, height: 6)
                                .shadow(color: (context.state.isActive ? Color.green : Color.orange).opacity(0.5), radius: 1)
                            
                            Text(context.state.isActive ? "Active" : "Paused")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(context.state.isActive ? .green : .orange)
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            (context.state.isActive ? Color.green : Color.orange).opacity(0.15)
                        )
                        .cornerRadius(8)
                    }
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: context.state.currentPhase.icon)
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    if context.state.isActive {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 4, height: 4)
                    }
                }
            } compactTrailing: {
                Text(formatTimeRemaining(context.state.timeRemaining))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            } minimal: {
                HStack(spacing: 3) {
                    Image(systemName: context.state.currentPhase.icon)
                        .font(.caption2)
                        .foregroundColor(.white)
                    
                    if context.state.isActive {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 3, height: 3)
                    }
                }
            }
        }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let totalMinutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if minutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h:\(String(format: "%02d", minutes))"
            }
        } else {
            if seconds == 0 {
                return "\(totalMinutes)m"
            } else {
                return "\(totalMinutes)m:\(String(format: "%02d", seconds))"
            }
        }
    }
}

struct FocusLiveActivityView: View {
    let context: ActivityViewContext<FocusZoneWidgetAttributes>
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with improved styling
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("FocusZen+")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text(context.state.taskTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Time display with better styling
                VStack(alignment: .trailing, spacing: 6) {
                    Text(formatTimeRemaining(context.state.timeRemaining))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                    Text("remaining")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Progress Section with enhanced design
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: context.state.currentPhase.icon)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(context.state.currentPhase.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // Enhanced progress bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.9)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, UIScreen.main.bounds.width * 0.7 * context.state.progress), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: context.state.progress)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Status Section with improved layout
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Text("Session \(context.state.completedSessions + 1) of \(context.state.totalSessions)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Status indicator with better styling
                HStack(spacing: 6) {
                    Circle()
                        .fill(context.state.isActive ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                        .shadow(color: (context.state.isActive ? Color.green : Color.orange).opacity(0.5), radius: 2)
                    
                    Text(context.state.isActive ? "Active" : "Paused")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(context.state.isActive ? .green : .orange)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    (context.state.isActive ? Color.green : Color.orange).opacity(0.15)
                )
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.15, blue: 0.35),
                    Color(red: 0.05, green: 0.1, blue: 0.25),
                    Color(red: 0.02, green: 0.05, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let totalMinutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if minutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h:\(String(format: "%02d", minutes))"
            }
        } else {
            if seconds == 0 {
                return "\(totalMinutes)m"
            } else {
                return "\(totalMinutes)m:\(String(format: "%02d", seconds))"
            }
        }
    }
}

extension FocusZoneWidgetAttributes {
    fileprivate static var preview: FocusZoneWidgetAttributes {
        FocusZoneWidgetAttributes(
            taskId: "preview-task",
            taskType: "work",
            focusMode: "deep_focus",
            sessionDuration: 1500,
            breakDuration: 300
        )
    }
}

extension FocusZoneWidgetAttributes.ContentState {
    fileprivate static var focus: FocusZoneWidgetAttributes.ContentState {
        FocusZoneWidgetAttributes.ContentState(
            taskTitle: "Complete Project Proposal",
            taskDescription: "Write the technical specifications and timeline",
            startTime: Date(),
            endTime: Date().addingTimeInterval(1500),
            isActive: true,
            timeRemaining: 1200,
            progress: 0.2,
            currentPhase: .focus,
            totalSessions: 4,
            completedSessions: 1
        )
    }
    
    fileprivate static var breakTime: FocusZoneWidgetAttributes.ContentState {
        FocusZoneWidgetAttributes.ContentState(
            taskTitle: "Code Review",
            taskDescription: "Review pull requests and provide feedback",
            startTime: Date(),
            endTime: Date().addingTimeInterval(300),
            isActive: false,
            timeRemaining: 180,
            progress: 0.4,
            currentPhase: .shortBreak,
            totalSessions: 4,
            completedSessions: 2
        )
    }
}

#Preview("Live Activity", as: .content, using: FocusZoneWidgetAttributes.preview) {
   FocusZoneWidgetLiveActivity()
} contentStates: {
    FocusZoneWidgetAttributes.ContentState.focus
    FocusZoneWidgetAttributes.ContentState.breakTime
}
