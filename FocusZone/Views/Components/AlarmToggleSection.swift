import SwiftUI

struct AlarmToggleSection: View {
    @Binding var alarmEnabled: Bool
    @ObservedObject var alarmService: AlarmService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("task_alarm", comment: "Task Alarm"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(NSLocalizedString("task_alarm_description", comment: "Get notified when it's time to start this task"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $alarmEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
            }
            
            if alarmEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: alarmService.isAlarmKitSupported ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(alarmService.isAlarmKitSupported ? .green : .orange)
                            .font(.system(size: 16))
                        
                        Text(alarmService.isAlarmKitSupported ? 
                             NSLocalizedString("alarmkit_supported", comment: "AlarmKit supported message") : 
                             NSLocalizedString("alarmkit_fallback", comment: "AlarmKit fallback message"))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    if !alarmService.isAuthorized && alarmService.isAlarmKitSupported {
                        Button(NSLocalizedString("grant_alarm_permission", comment: "Grant Alarm Permission")) {
                            _Concurrency.Task {
                                await alarmService.requestAuthorization()
                            }
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                    }
                }
                .padding(.leading, 36)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    AlarmToggleSection(
        alarmEnabled: .constant(true),
        alarmService: AlarmService.shared
    )
    .padding()
}
