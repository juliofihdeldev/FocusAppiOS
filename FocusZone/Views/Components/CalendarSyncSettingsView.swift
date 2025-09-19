import SwiftUI
import EventKit

struct CalendarSyncSettingsView: View {
    @StateObject private var calendarSync = CalendarSyncService.shared
    @Environment(\.modelContext) private var modelContext
    @State private var showingPermissionAlert = false
    @State private var showingSyncAlert = false
    @State private var syncMessage = ""
    @State private var isImporting = false
    @State private var importableEvents: [EKEvent] = []
    
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
                VStack(spacing: 12) {
                    Button(action: {
                        syncFromCalendar()
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Check Calendar Events")
                        }
                        .font(AppFonts.subheadline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.accent)
                        .cornerRadius(10)
                    }
                    
                    if !importableEvents.isEmpty {
                        Button(action: {
                            importEvents()
                        }) {
                            HStack {
                                if isImporting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                }
                                Text(isImporting ? "Importing..." : "Import \(importableEvents.count) Events")
                            }
                            .font(AppFonts.subheadline())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(10)
                        }
                        .disabled(isImporting)
                    }
                    
                    Text("Import all events from your calendar as tasks")
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
        _Concurrency.Task {
            let events = await calendarSync.getImportableCalendarEvents()
            await MainActor.run {
                importableEvents = events
                if events.isEmpty {
                    syncMessage = "No events found in your calendar. Make sure you have events scheduled in the next 30 days."
                } else {
                    syncMessage = "Found \(events.count) events in your calendar. You can import them as tasks below."
                }
                showingSyncAlert = true
            }
        }
    }
    
    private func importEvents() {
        guard !importableEvents.isEmpty else { return }
        
        isImporting = true
        _Concurrency.Task {
            let importedTasks = calendarSync.importCalendarEventsAsTasks(importableEvents, modelContext: modelContext)
            await MainActor.run {
                isImporting = false
                syncMessage = "Successfully imported \(importedTasks.count) tasks from your calendar!"
                showingSyncAlert = true
                importableEvents = []
            }
        }
    }
}

#Preview {
    CalendarSyncSettingsView()
        .padding()
}
