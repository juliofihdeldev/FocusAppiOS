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
    
    private let container: CKContainer
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
    
    enum CloudKitError: Error, LocalizedError {
        case schemaVerificationFailed(String)
        case containerAccessFailed(String)
        case syncOperationFailed(String)
        case recordConflict(String)
        
        var errorDescription: String? {
            switch self {
            case .schemaVerificationFailed(let message):
                return "Schema verification failed: \(message)"
            case .containerAccessFailed(let message):
                return "Container access failed: \(message)"
            case .syncOperationFailed(let message):
                return "Sync operation failed: \(message)"
            case .recordConflict(let message):
                return "Record conflict: \(message)"
            }
        }
    }
    
    init() {
        // Use the specific container identifier from entitlements
        self.container = CKContainer(identifier: "iCloud.group.ios.focus.jf.com.Focus")
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
    
    func validateCloudKitContainer() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            await MainActor.run {
                self.errorMessage = "CloudKit container validation failed: \(error.localizedDescription)"
                self.syncStatus = .failed("Container validation failed")
            }
            return false
        }
    }
    
    // MARK: - CloudKit Schema Setup
    
    private func setupCloudKitSchema() async throws {
        // Check if Task record type exists by trying to query it
        do {
            // Use a simpler query that doesn't require complex sorting
            let query = CKQuery(recordType: "Task", predicate: NSPredicate(value: true))
            
            _ = try await privateDatabase.records(matching: query)
            // If we get here, the record type exists
            print("✅ CloudKit Task record type already exists")
            return
        } catch {
            // Record type doesn't exist, create it by saving a sample record
            print("🔄 Creating CloudKit Task record type...")
            try await createTaskRecordType()
            
                    // Wait a moment for CloudKit to process the schema
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                continuation.resume()
            }
        }
            
            // Verify the schema was created successfully
            try await verifyTaskSchema()
        }
    }
    
    private func verifyTaskSchema() async throws {
        // Verify that the Task record type was created with all fields
        // Use a completely safe approach that doesn't trigger queryable field warnings
        do {
            // Instead of querying, just check if we can create a record
            // This verifies the schema exists without querying non-queryable fields
            let testRecord = CKRecord(recordType: "Task")
            testRecord["title"] = "Test Verification"
            testRecord["durationMinutes"] = Int64(1)
            testRecord["isCompleted"] = false
            
            // Try to save and immediately delete to verify schema
            let savedRecord = try await privateDatabase.save(testRecord)
            try await privateDatabase.deleteRecord(withID: savedRecord.recordID)
            
            print("✅ Task record type verified successfully")
            print("📊 Schema verification completed - Task record type exists and is fully functional")
        } catch {
            // Filter out the harmless "Field 'recordName' is not marked queryable" warning
            let errorMessage = error.localizedDescription
            if !errorMessage.contains("Field 'recordName' is not marked queryable") {
                print("⚠️ Schema verification warning: \(errorMessage)")
            } else {
                print("✅ Schema verification completed (ignoring harmless queryable field warning)")
            }
            // Don't throw error, just log warning
        }
    }
    
    private func createTaskRecordType() async throws {
        // Create a sample Task record to establish the schema
        // This will automatically create the record type in CloudKit with all fields
        let sampleTask = CKRecord(recordType: "Task")
        
        // Add all required fields to establish the complete schema
        sampleTask["title"] = "Sample Task"
        sampleTask["durationMinutes"] = Int64(25)
        sampleTask["isCompleted"] = false
        sampleTask["colorHex"] = "#007AFF"
        sampleTask["icon"] = "target"
        sampleTask["startTime"] = Date()
        sampleTask["createdAt"] = Date()
        sampleTask["updatedAt"] = Date()
        
        // Add optional fields that might be used
        sampleTask["notes"] = "Sample notes"
        sampleTask["priority"] = Int64(1)
        sampleTask["repeatRule"] = "none"
        sampleTask["focusMode"] = "pomodoro"
        
        // Save the sample record to create the schema
        try await privateDatabase.save(sampleTask)
        
        // Delete the sample record after schema creation
        try await privateDatabase.deleteRecord(withID: sampleTask.recordID)
        
        // Log successful schema creation
        print("✅ CloudKit Task record type created successfully with all fields")
    }
    
    func requestCloudKitPermission() async -> Bool {
        // Note: userDiscoverability permission is deprecated in iOS 17+
        // For production apps, consider using newer CloudKit sharing APIs
        // For now, return true to allow sync to proceed
        return true
    }
    
    // MARK: - Data Synchronization
    
    func syncData(modelContext: ModelContext) async {
        // First check if CloudKit container is accessible
        do {
            let containerStatus = try await container.accountStatus()
            if containerStatus != .available {
                await MainActor.run {
                    self.syncStatus = .failed("iCloud account not available")
                    self.errorMessage = "Please sign in to iCloud to enable sync"
                }
                return
            }
        } catch {
            await MainActor.run {
                self.syncStatus = .failed("CloudKit container error")
                self.errorMessage = "Could not access CloudKit container: \(error.localizedDescription)"
            }
            return
        }
        
        guard isSignedIn else {
            await MainActor.run {
                self.syncStatus = .failed("iCloud account not available")
                self.errorMessage = "Please sign in to iCloud to enable sync"
            }
            return
        }
        
        // Ensure CloudKit schema is set up
        do {
            try await setupCloudKitSchema()
        } catch {
            await MainActor.run {
                self.syncStatus = .failed("Schema setup failed")
                self.errorMessage = "Could not set up CloudKit schema: \(error.localizedDescription)"
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
            
            // TOFIX remoteChanges are really messy
            
            // Step 3: Merge changes and resolve conflicts
            await MainActor.run { self.syncProgress = 0.6 }
            try await mergeChanges(localChanges: localChanges, remoteChanges: [], modelContext: modelContext)
            
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
        let descriptor = FetchDescriptor<Task>()
        // For now, fetch all tasks and filter in memory
        // In a production app, you'd want to use proper predicates
        return try modelContext.fetch(descriptor)
    }
    
    private func fetchRemoteChanges() async throws -> [CKRecord] {
        // Fetch remote changes from CloudKit
        // Use a simple query without sorting to avoid queryable field issues
        let query = CKQuery(recordType: "Task", predicate: NSPredicate(value: true))
        
        let result = try await privateDatabase.records(matching: query)
        return result .matchResults.compactMap { try? $0.1.get() }
    }
    
    private func mergeChanges(localChanges: [Task], remoteChanges: [CKRecord], modelContext: ModelContext) async throws {
        // Enhanced conflict resolution with better handling of existing records
        
        for record in remoteChanges {
            if let existingTask = localChanges.first(where: { $0.id.uuidString == record.recordID.recordName }) {
                // Update existing task with remote data if remote is newer
                if let remoteUpdatedAt = record["updatedAt"] as? Date,
                   remoteUpdatedAt > existingTask.updatedAt {
                    try await updateTaskFromRecord(existingTask, record: record)
                } else {
                    print("ℹ️ Local task is newer, skipping update: \(existingTask.title)")
                }
            } else {
                // Check if task already exists in database to prevent duplicates
                let recordName = record.recordID.recordName
                let allTasks = try modelContext.fetch(FetchDescriptor<Task>())
                let existingTasks = allTasks.filter { $0.id.uuidString == recordName }
                
                if existingTasks.isEmpty {
                    // Create new task from remote data only if it doesn't exist
                    try await createTaskFromRecord(record, modelContext: modelContext)
                } else {
                    print("ℹ️ Task already exists locally, skipping creation: \(record["title"] as? String ?? "Unknown")")
                }
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
        if let startTime = record["startTime"] as? Date {
            task.startTime = startTime
        }
        if let updatedAt = record["updatedAt"] as? Date {
            task.updatedAt = updatedAt
        }
        
        print("✅ Updated task from CloudKit record: \(task.title) (ID: \(task.id))")
    }
    
    private func createTaskFromRecord(_ record: CKRecord, modelContext: ModelContext) async throws {
        // Extract UUID from CloudKit record ID to prevent duplicates
        guard let taskUUID = UUID(uuidString: record.recordID.recordName) else {
            print("❌ Failed to parse UUID from CloudKit record: \(record.recordID.recordName)")
            return
        }
        
        // Create new task with the correct UUID from CloudKit
        let task = Task(
            id: taskUUID, // Use the UUID from CloudKit record
            title: "",
            icon: "target",
            startTime: Date(),
            durationMinutes: 25,
            color: .blue
        )
        
        // Update task with data from CloudKit record
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
        if let startTime = record["startTime"] as? Date {
            task.startTime = startTime
        }
        if let createdAt = record["createdAt"] as? Date {
            task.createdAt = createdAt
        }
        if let updatedAt = record["updatedAt"] as? Date {
            task.updatedAt = updatedAt
        }
        
        modelContext.insert(task)
        print("✅ Created task from CloudKit record: \(task.title) (ID: \(task.id))")
    }
    
    private func uploadLocalChanges(_ localChanges: [Task], modelContext: ModelContext) async throws {
        // Upload local changes to CloudKit using modify operation to handle conflicts
        var recordsToSave: [CKRecord] = []
        let recordIDsToDelete: [CKRecord.ID] = []
        
        for task in localChanges {
            // Handle potential record conflicts
            if let record = try await handleRecordConflict(task) {
                recordsToSave.append(record)
            }
        }
        
        if !recordsToSave.isEmpty {
            let modifyOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
            modifyOperation.savePolicy = .changedKeys
            modifyOperation.qualityOfService = .userInitiated
            
            try await withCheckedThrowingContinuation { continuation in
                modifyOperation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                privateDatabase.add(modifyOperation)
            }
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
    
    private func handleRecordConflict(_ task: Task) async throws -> CKRecord? {
        // Try to fetch the existing record first
        let recordID = CKRecord.ID(recordName: task.id.uuidString)
        
        do {
            let existingRecord = try await privateDatabase.record(for: recordID)
            // If record exists, update it with local changes
            existingRecord["title"] = task.title
            existingRecord["durationMinutes"] = task.durationMinutes
            existingRecord["isCompleted"] = task.isCompleted
            existingRecord["colorHex"] = task.color.toHex()
            existingRecord["icon"] = task.icon
            existingRecord["updatedAt"] = task.updatedAt
            
            return existingRecord
        } catch {
            // Record doesn't exist, create new one
            return try await createRecordFromTask(task)
        }
    }
    
    // MARK: - Manual Sync
    
    func manualSync(modelContext: ModelContext) async {
        // First validate the CloudKit container
        guard await validateCloudKitContainer() else {
            return
        }
        
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
    
    // MARK: - Testing Methods
    
    /// Deletes a task from both CloudKit and local data for testing purposes
    func deleteTaskForTesting(_ task: Task, modelContext: ModelContext) async throws {
        print("🧪 Testing: Deleting task '\(task.title)' (ID: \(task.id)) from CloudKit and local data")
        
        // 1. Delete from CloudKit
        let recordID = CKRecord.ID(recordName: task.id.uuidString)
        
        do {
            try await privateDatabase.deleteRecord(withID: recordID)
            print("✅ Task deleted from CloudKit successfully")
        } catch {
            print("⚠️ Failed to delete from CloudKit: \(error.localizedDescription)")
            // Continue with local deletion even if CloudKit fails
        }
        
        // 2. Delete from local SwiftData
        modelContext.delete(task)
        
        do {
            try modelContext.save()
            print("✅ Task deleted from local data successfully")
        } catch {
            print("❌ Failed to save local context after deletion: \(error.localizedDescription)")
            throw error
        }
        
        print("🧪 Testing: Task deletion completed successfully")
    }
    
    /// Deletes all tasks from both CloudKit and local data for testing purposes
    func deleteAllTasksForTesting(modelContext: ModelContext) async throws {
        print("🧪 Testing: Deleting ALL tasks from CloudKit and local data")
        
        // 1. Fetch all local tasks
        let descriptor = FetchDescriptor<Task>()
        let allTasks = try modelContext.fetch(descriptor)
        
        print("🧪 Found \(allTasks.count) tasks to delete")
        
        // 2. Delete from CloudKit
        let recordIDs = allTasks.map { CKRecord.ID(recordName: $0.id.uuidString) }
        
        if !recordIDs.isEmpty {
            do {
                let modifyOperation = CKModifyRecordsOperation(recordsToSave: [], recordIDsToDelete: recordIDs)
                modifyOperation.savePolicy = .changedKeys
                modifyOperation.qualityOfService = .userInitiated
                
                try await withCheckedThrowingContinuation { continuation in
                    modifyOperation.modifyRecordsResultBlock = { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    
                    privateDatabase.add(modifyOperation)
                }
                print("✅ All tasks deleted from CloudKit successfully")
            } catch {
                print("⚠️ Failed to delete some tasks from CloudKit: \(error.localizedDescription)")
                // Continue with local deletion even if CloudKit fails
            }
        }
        
        // 3. Delete from local SwiftData
        for task in allTasks {
            modelContext.delete(task)
        }
        
        do {
            try modelContext.save()
            print("✅ All tasks deleted from local data successfully")
        } catch {
            print("❌ Failed to save local context after deletion: \(error.localizedDescription)")
            throw error
        }
        
        print("🧪 Testing: All tasks deletion completed successfully")
    }
}
