import SwiftUI
import EventKit

struct CalendarSyncSettingsView: View {
    @StateObject private var calendarSync = CalendarSyncService.shared
    @State private var showingPermissionAlert = false
    @State private var showingSyncAlert = false
    @State private var syncMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Sync Toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Calendar Sync")
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Sync your focus tasks with your calendar")
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: $calendarSync.syncEnabled)
                    .onChange(of: calendarSync.syncEnabled) { _, newValue in
                        if newValue {
                            enableSync()
                        } else {
                            calendarSync.disableSync()
                        }
                    }
            }
            
            // Permission Status
            if !calendarSync.isAuthorized {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Calendar access required")
                        .font(AppFonts.caption())
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button("Grant Access") {
                        requestCalendarAccess()
                    }
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.accent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                // Sync Status
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Calendar access granted")
                        .font(AppFonts.caption())
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Sync Actions
            if calendarSync.isAuthorized && calendarSync.syncEnabled {
                VStack(spacing: 8) {
                    Button(action: {
                        syncFromCalendar()
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("Import from Calendar")
                        }
                        .font(AppFonts.subheadline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.accent)
                        .cornerRadius(10)
                    }
                    
                    Text("Import focus sessions from your calendar")
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            calendarSync.loadSyncSettings()
        }
        .alert("Calendar Access Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable calendar access in Settings to sync your focus tasks.")
        }
        .alert("Sync Complete", isPresented: $showingSyncAlert) {
            Button("OK") { }
        } message: {
            Text(syncMessage)
        }
    }
    
    private func enableSync() {
        _Concurrency.Task {
            let granted = await calendarSync.requestCalendarAccess()
            if granted {
                calendarSync.enableSync()
            } else {
                await MainActor.run {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func requestCalendarAccess() {
        _Concurrency.Task {
            let granted = await calendarSync.requestCalendarAccess()
            if !granted {
                await MainActor.run {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func syncFromCalendar() {
        // This would need to be implemented with a model context
        // For now, just show a message
        syncMessage = "Calendar sync feature coming soon! This will import focus sessions from your calendar."
        showingSyncAlert = true
    }
}

#Preview {
    CalendarSyncSettingsView()
        .padding()
}
