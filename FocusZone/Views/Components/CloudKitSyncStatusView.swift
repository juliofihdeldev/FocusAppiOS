import SwiftUI
import CloudKit

struct CloudKitSyncStatusView: View {
    @ObservedObject var cloudSyncManager: CloudSyncManager
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "icloud")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("iCloud Sync")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // Sync Status Indicator
                syncStatusIndicator
            }
            
            // Sync Status Description
            if cloudSyncManager.isSyncing {
                Text("Syncing with iCloud...")
                    .font(AppFonts.caption())
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.leading)
            } else {
                Text(cloudSyncManager.getSyncStatusDescription())
                    .font(AppFonts.caption())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            // Progress Bar (when syncing)
            if cloudSyncManager.isSyncing {
                VStack(spacing: 8) {
                    ProgressView(value: cloudSyncManager.syncProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                    
                    Text("Syncing... \(Int(cloudSyncManager.syncProgress * 100))%")
                        .font(AppFonts.caption())
                        .foregroundColor(.blue)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                // Manual Sync Button
                Button(action: {
                    _Concurrency.Task {
                        await cloudSyncManager.manualSync(modelContext: modelContext)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text("Sync Now")
                            .font(AppFonts.caption())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(cloudSyncManager.isSyncing ? .gray : .blue)
                    )
                }
                .disabled(cloudSyncManager.isSyncing || !cloudSyncManager.isSignedIn)
                
                // Account Status
                if !cloudSyncManager.isSignedIn {
                    Button(action: {
                        // Open iCloud settings
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.caption)
                            Text("Sign In to iCloud")
                                .font(AppFonts.caption())
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange, lineWidth: 1)
                        )
                    }
                }
                
                Spacer()
            }
            
            // Success Message (when sync completes)
            if case .completed = cloudSyncManager.syncStatus {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("Sync completed successfully")
                        .font(AppFonts.caption())
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.1))
                )
            }
            
            // Error Message (if any) - Filter out harmless warnings
            if let errorMessage = cloudSyncManager.errorMessage,
               !errorMessage.contains("Field 'recordName' is not marked queryable") {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(errorMessage)
                        .font(AppFonts.caption())
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.card)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private var syncStatusIndicator: some View {
        switch cloudSyncManager.syncStatus {
        case .idle:
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
        case .syncing:
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
                .scaleEffect(1.2)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: cloudSyncManager.syncProgress)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.caption)
        }
    }
}

#Preview {
    CloudKitSyncStatusView(cloudSyncManager: CloudSyncManager())
        .padding()
        .background(Color.gray.opacity(0.1))
}
