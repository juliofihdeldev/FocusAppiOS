import SwiftUI
import WidgetKit
import ActivityKit

struct FocusLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            FocusLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: context.state.currentPhase.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                        Text(context.state.currentPhase.displayName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatTimeRemaining(context.state.timeRemaining))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("remaining")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        Text(context.state.taskTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .scaleEffect(x: 1, y: 0.8)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("Session \(context.state.completedSessions + 1) of \(context.state.totalSessions)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        if context.state.isActive {
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        } else {
                            Text("Paused")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.currentPhase.icon)
                    .foregroundColor(.white)
            } compactTrailing: {
                Text(formatTimeRemaining(context.state.timeRemaining))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: context.state.currentPhase.icon)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct FocusLiveActivityView: View {
    let context: ActivityViewContext<FocusActivityAttributes>
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FocusZone")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(context.state.taskTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTimeRemaining(context.state.timeRemaining))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("remaining")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Progress Section
            VStack(spacing: 8) {
                HStack {
                    Text(context.state.currentPhase.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                ProgressView(value: context.state.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .scaleEffect(x: 1, y: 1.2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Status Section
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: context.state.currentPhase.icon)
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("Session \(context.state.completedSessions + 1) of \(context.state.totalSessions)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if context.state.isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text("Paused")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.05, green: 0.1, blue: 0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview("Live Activity", as: .content, using: FocusActivityAttributes(
    taskId: "preview-task",
    taskType: "work",
    focusMode: "deep_focus",
    sessionDuration: 1500,
    breakDuration: 300
)) {
    FocusLiveActivityWidget()
} contentStates: {
    FocusActivityAttributes.ContentState(
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
    FocusActivityAttributes.ContentState(
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
