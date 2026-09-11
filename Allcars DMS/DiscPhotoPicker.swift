import SwiftUI
import PhotosUI
import UIKit

struct DiscPhotoPicker: View {

    @Environment(\.dismiss)
    private var dismiss

    @State private var selectedItem: PhotosPickerItem?

    @State private var isScanning = false
    @State private var errorMessage: String?

    let onResult: (String) -> Void

    var body: some View {

        NavigationStack {

            VStack(spacing: 24) {

                Image(
                    systemName: "photo.badge.magnifyingglass"
                )
                .font(.system(size: 72))
                .foregroundStyle(.secondary)

                Text("Choose Licence Disc Photo")
                    .font(.title2.bold())

                Text(
                    "Choose a clear photo where the PDF417 barcode on the vehicle licence disc is visible."
                )
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {

                    Label(
                        "Choose from Photos",
                        systemImage: "photo.on.rectangle"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                if isScanning {

                    VStack(spacing: 10) {

                        ProgressView()

                        Text("Reading licence disc...")
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {

                    VStack(spacing: 10) {

                        Image(
                            systemName:
                                "exclamationmark.triangle.fill"
                        )
                        .font(.title2)
                        .foregroundStyle(.red)

                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Licence Disc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Cancel") {

                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItem) {
                _, newItem in

                guard let newItem else {
                    return
                }

                Task {

                    await scanPhoto(
                        item: newItem
                    )
                }
            }
        }
    }

    // MARK: - Scan Photo

    @MainActor
    private func scanPhoto(
        item: PhotosPickerItem
    ) async {

        isScanning = true

        errorMessage = nil

        defer {

            isScanning = false
        }

        do {

            guard
                let imageData =
                    try await item.loadTransferable(
                        type: Data.self
                    )
            else {

                throw BarcodeDetectorError.invalidImage
            }

            guard
                let image =
                    UIImage(data: imageData)
            else {

                throw BarcodeDetectorError.invalidImage
            }

            let payload =
                try await BarcodeDetector.detectPDF417(
                    in: image
                )

            print(
                "========== LICENCE DISC =========="
            )

            print(payload)

            print(
                "=================================="
            )

            onResult(payload)

            dismiss()

        } catch {

            errorMessage =
                error.localizedDescription

            print(
                "Disc photo scan error:",
                error.localizedDescription
            )
        }
    }
}
