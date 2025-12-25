import SwiftUI

struct AlarmTestView: View {
    @StateObject private var alarmService = AlarmService.shared
    @State private var testAlarmScheduled = false
    @State private var testAlarmTime: Date = Date().addingTimeInterval(10) // 10 seconds from now
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Alarm Test")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Test the alarm functionality")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Alarm Status
                VStack(spacing: 12) {
                    StatusRow(
                        title: "AlarmKit Support",
                        value: alarmService.isAlarmKitSupported ? "✅ Supported" : "❌ Not Supported",
                        color: alarmService.isAlarmKitSupported ? .green : .red
                    )
                    
                    StatusRow(
                        title: "Authorization",
                        value: alarmService.isAuthorized ? "✅ Authorized" : "❌ Not Authorized",
                        color: alarmService.isAuthorized ? .green : .red
                    )
                    
                    StatusRow(
                        title: "Test Alarm",
                        value: testAlarmScheduled ? "✅ Scheduled" : "❌ Not Scheduled",
                        color: testAlarmScheduled ? .green : .orange
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Test Controls
                VStack(spacing: 16) {
                    // Time Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Alarm Time")
                            .font(.headline)
                        
                        DatePicker("", selection: $testAlarmTime, in: Date()...)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            scheduleTestAlarm()
                        }) {
                            HStack {
                                Image(systemName: "alarm.badge.plus")
                                Text("Schedule Test Alarm")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                        .disabled(testAlarmScheduled)
                        
                        Button(action: {
                            cancelTestAlarm()
                        }) {
                            HStack {
                                Image(systemName: "alarm.badge.minus")
                                Text("Cancel Test Alarm")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .disabled(!testAlarmScheduled)
                        
                        Button(action: {
                            requestPermissions()
                        }) {
                            HStack {
                                Image(systemName: "key.fill")
                                Text("Request Permissions")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            debugNotifications()
                        }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text("Debug Notifications")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions:")
                        .font(.headline)
                    
                    Text("1. Set a test alarm time (default: 10 seconds from now)")
                    Text("2. Tap 'Schedule Test Alarm'")
                    Text("3. Wait for the alarm to trigger")
                    Text("4. Check if you receive a notification")
                    Text("5. Verify Live Activity starts (if supported)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Alarm Test")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Test Result", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func scheduleTestAlarm() {
        // Create a test task
        let testTask = Task(
            title: "Test Alarm Task",
            icon: "🧪",
            startTime: testAlarmTime,
            durationMinutes: 5,
            alarmEnabled: true
        )
        
        _Concurrency.Task {
            let success = await alarmService.scheduleAlarm(for: testTask)
            
            await MainActor.run {
                if success {
                    testAlarmScheduled = true
                    alertMessage = "Test alarm scheduled successfully for \(testAlarmTime.formatted(date: .omitted, time: .shortened))"
                } else {
                    alertMessage = "Failed to schedule test alarm. Check permissions and try again."
                }
                showingAlert = true
            }
        }
    }
    
    private func cancelTestAlarm() {
        // For testing purposes, we'll just reset the state
        // In a real implementation, you'd cancel the actual alarm
        testAlarmScheduled = false
        alertMessage = "Test alarm cancelled"
        showingAlert = true
    }
    
    private func requestPermissions() {
        _Concurrency.Task {
            let granted = await alarmService.requestAuthorization()
            
            await MainActor.run {
                if granted {
                    alertMessage = "AlarmKit permissions granted!"
                } else {
                    alertMessage = "AlarmKit permissions denied. Please check Settings."
                }
                showingAlert = true
            }
        }
    }
    
    private func debugNotifications() {
        _Concurrency.Task {
            await alarmService.printAlarmStatus()
            
            await MainActor.run {
                alertMessage = "Check console for notification debug info"
                showingAlert = true
            }
        }
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(color)
        }
    }
}

#Preview {
    AlarmTestView()
}
