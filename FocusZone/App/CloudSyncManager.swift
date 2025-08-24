import Foundation
import CloudKit
import SwiftUI
import SwiftData

@MainActor
final class CloudSyncManager: ObservableObject {
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var isSignedIn: Bool = false
    @Published var isSyncing: Bool = false
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    @Published var syncStatus: SyncStatus = .idle
    
    private let container = CKContainer.default()
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    
    enum SyncStatus {
        case idle
        case syncing
        case completed
        case failed(String)
        
        var description: String {
            switch self {
            case .idle:
                return "Ready to sync"
            case .syncing:
                return "Syncing..."
            case .completed:
                return "Sync completed"
            case .failed(let error):
                return "Sync failed: \(error)"
            }
        }
    }
    
    init() {
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        refreshAccountStatus()
    }
    
    // MARK: - Account Management
    
    func refreshAccountStatus() {
        container.accountStatus { [weak self] status, error in
            _Concurrency.Task { @MainActor in
                self?.accountStatus = status
                self?.isSignedIn = (status == .available)
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.syncStatus = .failed(error.localizedDescription)
                }
            }
        }
    }
    
    func requestCloudKitPermission() async -> Bool {
        // Note: userDiscoverability permission is deprecated in iOS 17+
        // For production apps, consider using newer CloudKit sharing APIs
        // For now, return true to allow sync to proceed
        return true
    }
    
    // MARK: - Data Synchronization
    
    func syncData(modelContext: ModelContext) async {
        guard isSignedIn else {
            await MainActor.run {
                self.syncStatus = .failed("iCloud account not available")
                self.errorMessage = "Please sign in to iCloud to enable sync"
            }
            return
        }
        
        await MainActor.run {
            self.isSyncing = true
            self.syncStatus = .syncing
            self.syncProgress = 0.0
        }
        
        do {
            // Step 1: Fetch local changes
            await MainActor.run { self.syncProgress = 0.2 }
            let localChanges = try await fetchLocalChanges(modelContext: modelContext)
            
            // Step 2: Fetch remote changes
            await MainActor.run { self.syncProgress = 0.4 }
            let remoteChanges = try await fetchRemoteChanges()
            
            // Step 3: Merge changes and resolve conflicts
            await MainActor.run { self.syncProgress = 0.6 }
            try await mergeChanges(localChanges: localChanges, remoteChanges: remoteChanges, modelContext: modelContext)
            
            // Step 4: Upload local changes
            await MainActor.run { self.syncProgress = 0.8 }
            try await uploadLocalChanges(localChanges, modelContext: modelContext)
            
            // Step 5: Update sync status
            await MainActor.run {
                self.syncProgress = 1.0
                self.isSyncing = false
                self.lastSyncDate = Date()
                self.syncStatus = .completed
                self.errorMessage = nil
            }
            
            // Reset progress after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                _Concurrency.Task { @MainActor in
                    self.syncProgress = 0.0
                    self.syncStatus = .idle
                }
            }
            
        } catch {
            await MainActor.run {
                self.isSyncing = false
                self.syncStatus = .failed(error.localizedDescription)
                self.errorMessage = "Sync failed: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Private Sync Methods
    
    private func fetchLocalChanges(modelContext: ModelContext) async throws -> [Task] {
        // Fetch tasks that have been modified locally
        var descriptor = FetchDescriptor<Task>()
        // For now, fetch all tasks and filter in memory
        // In a production app, you'd want to use proper predicates
        return try modelContext.fetch(descriptor)
    }
    
    private func fetchRemoteChanges() async throws -> [CKRecord] {
        // Fetch remote changes from CloudKit
        let query = CKQuery(recordType: "Task", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        let result = try await privateDatabase.records(matching: query)
        return result.matchResults.compactMap { try? $0.1.get() }
    }
    
    private func mergeChanges(localChanges: [Task], remoteChanges: [CKRecord], modelContext: ModelContext) async throws {
        // Simple conflict resolution: remote wins for now
        // In a production app, you'd want more sophisticated conflict resolution
        
        for record in remoteChanges {
            if let existingTask = localChanges.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                // Update existing task with remote data
                try await updateTaskFromRecord(existingTask, record: record)
            } else {
                // Create new task from remote data
                try await createTaskFromRecord(record, modelContext: modelContext)
            }
        }
        
        try modelContext.save()
    }
    
    private func updateTaskFromRecord(_ task: Task, record: CKRecord) async throws {
        // Update task properties from CloudKit record
        if let title = record["title"] as? String {
            task.title = title
        }
        if let duration = record["durationMinutes"] as? Int {
            task.durationMinutes = duration
        }
        if let isCompleted = record["isCompleted"] as? Bool {
            task.isCompleted = isCompleted
        }
        if let colorHex = record["colorHex"] as? String {
            task.color = Color(hex: colorHex) ?? .blue
        }
        if let icon = record["icon"] as? String {
            task.icon = icon
        }
        
        task.updatedAt = Date()
    }
    
    private func createTaskFromRecord(_ record: CKRecord, modelContext: ModelContext) async throws {
        // Create new task from CloudKit record
        let task = Task(
            title: "",
            icon: "target",
            startTime: Date(),
            durationMinutes: 25,
            color: .blue
        )
        
        if let title = record["title"] as? String {
            task.title = title
        }
        if let duration = record["durationMinutes"] as? Int {
            task.durationMinutes = duration
        }
        if let isCompleted = record["isCompleted"] as? Bool {
            task.isCompleted = isCompleted
        }
        if let colorHex = record["colorHex"] as? String {
            task.color = Color(hex: colorHex) ?? .blue
        }
        if let icon = record["icon"] as? String {
            task.icon = icon
        }
        
        task.updatedAt = Date()
        task.createdAt = Date()
        
        modelContext.insert(task)
    }
    
    private func uploadLocalChanges(_ localChanges: [Task], modelContext: ModelContext) async throws {
        // Upload local changes to CloudKit
        for task in localChanges {
            let record = try await createRecordFromTask(task)
            try await privateDatabase.save(record)
        }
    }
    
    private func createRecordFromTask(_ task: Task) async throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: task.id.uuidString)
        let record = CKRecord(recordType: "Task", recordID: recordID)
        
        record["title"] = task.title
        record["durationMinutes"] = task.durationMinutes
        record["isCompleted"] = task.isCompleted
        record["colorHex"] = task.color.toHex()
        record["icon"] = task.icon
        record["createdAt"] = task.createdAt
        record["updatedAt"] = task.updatedAt
        
        return record
    }
    
    // MARK: - Manual Sync
    
    func manualSync(modelContext: ModelContext) async {
        await syncData(modelContext: modelContext)
    }
    
    // MARK: - Sync Status
    
    func getSyncStatusDescription() -> String {
        switch syncStatus {
        case .idle:
            if let lastSync = lastSyncDate {
                let formatter = RelativeDateTimeFormatter()
                return "Last synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
            }
            return "Ready to sync"
        case .syncing:
            return "Syncing... \(Int(syncProgress * 100))%"
        case .completed:
            return "Sync completed successfully"
        case .failed(let error):
            return "Sync failed: \(error)"
        }
    }
}
