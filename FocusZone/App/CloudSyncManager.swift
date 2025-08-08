import Foundation
import CloudKit
import SwiftUI

final class CloudSyncManager: ObservableObject {
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var isSignedIn: Bool = false
    @Published var errorMessage: String?

    func refreshAccountStatus() {
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.accountStatus = status
                self?.isSignedIn = (status == .available)
                if let error { self?.errorMessage = error.localizedDescription }
            }
        }
    }
}
