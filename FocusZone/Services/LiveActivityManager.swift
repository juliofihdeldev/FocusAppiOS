import Foundation
import ActivityKit
import SwiftUI

// Define the same attributes as the widget extension
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

// FocusPhase is already defined in FocusActivityAttributes.swift

@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: Activity<FocusZoneWidgetAttributes>?
    @Published var isLiveActivitySupported: Bool = false
    
    private init() {
        checkLiveActivitySupport()
    }
    
    private func checkLiveActivitySupport() {
        isLiveActivitySupported = ActivityAuthorizationInfo().areActivitiesEnabled
        print("Live Activity Support: \(isLiveActivitySupported)")
    }
    
    func startLiveActivity(for task: Task, sessionDuration: TimeInterval, breakDuration: TimeInterval? = nil) {
        print("🎯 LiveActivityManager: startLiveActivity called")
        print("🎯 Task: \(task.title)")
        print("🎯 Duration: \(sessionDuration)")
        print("🎯 Live Activity Support: \(isLiveActivitySupported)")
        
        guard isLiveActivitySupported else {
            print("❌ Live Activities are not supported on this device")
            return
        }
        
        // End any existing activity
        endCurrentActivity()
        
        print("🚀 Starting Live Activity for task: \(task.title)")
        
        // Calculate actual progress based on time already spent
        let totalDuration = TimeInterval(task.durationMinutes * 60)
        let timeAlreadySpent = totalDuration - sessionDuration
        let progress = timeAlreadySpent / totalDuration
        
        print("🎯 LiveActivityManager: Progress calculation:")
        print("🎯 - Total duration: \(totalDuration) seconds (\(task.durationMinutes) minutes)")
        print("🎯 - Session duration: \(sessionDuration) seconds")
        print("🎯 - Time already spent: \(timeAlreadySpent) seconds")
        print("🎯 - Calculated progress: \(progress) (\(Int(progress * 100))%)")
        
        let attributes = FocusZoneWidgetAttributes(
            taskId: task.id.uuidString,
            taskType: task.taskTypeRawValue ?? "work",
            focusMode: "deep_focus",
            sessionDuration: sessionDuration,
            breakDuration: breakDuration
        )
        
        let contentState = FocusZoneWidgetAttributes.ContentState(
            taskTitle: task.title,
            taskDescription: nil,
            startTime: Date(),
            endTime: Date().addingTimeInterval(sessionDuration),
            isActive: true,
            timeRemaining: sessionDuration,
            progress: progress,
            currentPhase: .focus,
            totalSessions: 1,
            completedSessions: 0
        )
        
        do {
            let activity = try Activity<FocusZoneWidgetAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            
            currentActivity = activity
            print("✅ Live Activity started successfully for task: \(task.title)")
            print("✅ Activity ID: \(activity.id)")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    func updateLiveActivity(
        timeRemaining: TimeInterval,
        progress: Double,
        currentPhase: FocusPhase,
        isActive: Bool,
        completedSessions: Int? = nil
    ) {
        guard let activity = currentActivity else { return }
        
        var updatedState = activity.content.state
        updatedState.timeRemaining = timeRemaining
        updatedState.progress = progress
        updatedState.currentPhase = currentPhase
        updatedState.isActive = isActive
        
        if let completedSessions = completedSessions {
            updatedState.completedSessions = completedSessions
        }
        
        _Concurrency.Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }
    
    func pauseLiveActivity() {
        guard let activity = currentActivity else { return }
        
        var updatedState = activity.content.state
        updatedState.isActive = false
        updatedState.currentPhase = .paused
        
        _Concurrency.Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }
    
    func resumeLiveActivity() {
        guard let activity = currentActivity else { return }
        
        var updatedState = activity.content.state
        updatedState.isActive = true
        updatedState.currentPhase = .focus
        
        _Concurrency.Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }
    
    func endCurrentActivity() {
        guard let activity = currentActivity else { return }
        
        var finalState = activity.content.state
        finalState.isActive = false
        finalState.currentPhase = .completed
        finalState.progress = 1.0
        finalState.timeRemaining = 0
        
        _Concurrency.Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        
        currentActivity = nil
        print("Live Activity ended")
    }
    
    func endActivityWithDelay() {
        guard let activity = currentActivity else { return }
        
        var finalState = activity.content.state
        finalState.isActive = false
        finalState.currentPhase = .completed
        finalState.progress = 1.0
        finalState.timeRemaining = 0
        
        _Concurrency.Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .after(Date().addingTimeInterval(5.0)))
        }
        
        currentActivity = nil
        print("Live Activity ended with delay")
    }
}
