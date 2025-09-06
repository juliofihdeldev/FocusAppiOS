import Foundation
import ActivityKit
import SwiftUI

@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: Activity<FocusActivityAttributes>?
    @Published var isLiveActivitySupported: Bool = false
    
    private init() {
        checkLiveActivitySupport()
    }
    
    private func checkLiveActivitySupport() {
        isLiveActivitySupported = ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    func startLiveActivity(for task: Task, sessionDuration: TimeInterval, breakDuration: TimeInterval? = nil) {
        guard isLiveActivitySupported else {
            print("Live Activities are not supported on this device")
            return
        }
        
        // End any existing activity
        endCurrentActivity()
        
        let attributes = FocusActivityAttributes(
            taskId: task.id.uuidString,
            taskType: task.taskTypeRawValue ?? "work",
            focusMode: "deep_focus",
            sessionDuration: sessionDuration,
            breakDuration: breakDuration
        )
        
        let contentState = FocusActivityAttributes.ContentState(
            taskTitle: task.title,
            taskDescription: nil,
            startTime: Date(),
            endTime: Date().addingTimeInterval(sessionDuration),
            isActive: true,
            timeRemaining: sessionDuration,
            progress: 0.0,
            currentPhase: .focus,
            totalSessions: 1,
            completedSessions: 0
        )
        
        do {
            let activity = try Activity<FocusActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            
            currentActivity = activity
            print("Live Activity started for task: \(task.title)")
        } catch {
            print("Failed to start Live Activity: \(error)")
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
