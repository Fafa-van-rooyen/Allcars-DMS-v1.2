import SwiftUI
import CloudKit
import UIKit
import CoreData

struct DealershipSharingView: View {
    @State private var dealership: Dealership?
    @State private var share: CKShare?
    @State private var cloudContainer: CKContainer?
    @State private var preparing = false
    @State private var errorMessage: String?
    @State private var dealerships: [Dealership] = []
    @State private var managingDealership: Dealership?
    @State private var recovering = false
    @State private var recoveryMessage: String?

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

                if dealerships.count > 1 {
                    Section("Sync Repair") {
                        Text("More than one dealership record was found. The dealership with the most vehicles is selected as the main dealership.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        ForEach(dealerships, id: \.objectID) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.objectID == dealership?.objectID ? "Main Dealership" : "Other Dealership")
                                        .font(.headline)
                                    Text("\(item.vehicles?.count ?? 0) vehicles")
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Manage Share") {
                                    manageShare(for: item)
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        Button {
                            recoverOtherDealerships()
                        } label: {
                            Label("Recover Vehicles into Main Dealership", systemImage: "arrow.triangle.merge")
                        }
                        .disabled(recovering || dealership == nil)

                        if recovering {
                            HStack {
                                ProgressView()
                                Text("Recovering vehicle records…")
                            }
                        }
                        if let recoveryMessage {
                            Text(recoveryMessage)
                                .font(.footnote)
                                .foregroundStyle(.green)
                        }
                    }
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
                        managingDealership = nil
                        loadDealership()
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
        do {
            dealership = try PersistenceController.shared.dealership()
            dealerships = try PersistenceController.shared.allDealerships()
        }
        catch { errorMessage = error.localizedDescription }
    }

    private func manageShare(for item: Dealership) {
        preparing = true
        managingDealership = item
        PersistenceController.shared.existingSharingInformation(for: item) { result in
            DispatchQueue.main.async {
                preparing = false
                switch result {
                case let .success((existingShare, container)):
                    share = existingShare
                    cloudContainer = container
                case let .failure(error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func recoverOtherDealerships() {
        guard let dealership else { return }
        recovering = true
        recoveryMessage = nil
        PersistenceController.shared.recoverUnsharedDealerships(into: dealership) { result in
            DispatchQueue.main.async {
                recovering = false
                switch result {
                case let .success(count):
                    recoveryMessage = count == 0
                        ? "No unshared vehicles needed recovery."
                        : "Recovered \(count) vehicle\(count == 1 ? "" : "s"). Keep the app open while CloudKit uploads them."
                    loadDealership()
                case let .failure(error):
                    errorMessage = error.localizedDescription
                }
            }
        }
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
