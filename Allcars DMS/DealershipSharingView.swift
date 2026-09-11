import SwiftUI
import CloudKit
import UIKit

struct DealershipSharingView: View {
    @State private var dealership: Dealership?
    @State private var share: CKShare?
    @State private var cloudContainer: CKContainer?
    @State private var preparing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Dealership") {
                    LabeledContent("Name", value: dealership?.name ?? "All Cars")
                    if let dealership {
                        LabeledContent("Vehicles", value: "\(dealership.vehicles?.count ?? 0)")
                    }
                }

                Section("Owner Access") {
                    Button {
                        prepareShare()
                    } label: {
                        Label("Share with Owner", systemImage: "person.2.badge.plus")
                    }
                    .disabled(dealership == nil || preparing)

                    if preparing {
                        HStack {
                            ProgressView()
                            Text("Preparing secure invitation…")
                        }
                    }

                    Text("Send this invitation to the owner's different Apple Account and choose Can Make Changes.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Dealership")
            .task { loadDealership() }
            .onReceive(NotificationCenter.default.publisher(for: .dealershipShareAccepted)) { _ in
                loadDealership()
            }
            .sheet(isPresented: Binding(
                get: { share != nil && cloudContainer != nil },
                set: { shown in
                    if !shown {
                        share = nil
                        cloudContainer = nil
                    }
                }
            )) {
                if let share, let cloudContainer {
                    CloudSharingController(share: share, container: cloudContainer)
                }
            }
            .alert(
                "CloudKit Sharing",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    @MainActor
    private func loadDealership() {
        do { dealership = try PersistenceController.shared.dealership() }
        catch { errorMessage = error.localizedDescription }
    }

    private func prepareShare() {
        guard let dealership else { return }
        preparing = true
        PersistenceController.shared.sharingInformation(for: dealership) { result in
            DispatchQueue.main.async {
                preparing = false
                switch result {
                case let .success((createdShare, container)):
                    share = createdShare
                    cloudContainer = container
                case let .failure(error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

private struct CloudSharingController: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowPrivate, .allowReadWrite]
        return controller
    }

    func updateUIViewController(
        _ controller: UICloudSharingController,
        context: Context
    ) {}

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func itemTitle(for csc: UICloudSharingController) -> String? {
            "All Cars Dealership"
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {}
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {}

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            print("CloudKit sharing screen failed:", error.localizedDescription)
        }
    }
}
