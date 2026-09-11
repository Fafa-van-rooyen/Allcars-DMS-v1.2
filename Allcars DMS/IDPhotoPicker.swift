import SwiftUI
import PhotosUI
import UIKit

struct IDPhotoPicker: View {

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
                    systemName: "person.text.rectangle"
                )
                .font(.system(size: 70))
                .foregroundStyle(.secondary)

                Text("Choose ID Photo")
                    .font(.title2.bold())

                Text(
                    "Choose a clear photo of the back of the South African Smart ID card where the PDF417 barcode is visible."
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

                    ProgressView(
                        "Reading ID barcode..."
                    )
                }

                if let errorMessage {

                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("South African ID")
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
                let data =
                    try await item.loadTransferable(
                        type: Data.self
                    ),
                let image =
                    UIImage(data: data)
            else {

                throw BarcodeDetectorError.invalidImage
            }

            let payload =
                try await BarcodeDetector.detectPDF417(
                    in: image
                )

            print("========== SA ID ==========")
            print(payload)
            print("===========================")

            onResult(payload)
            dismiss()

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }
}
//
//  IDPhotoPicker.swift
//  Allcars DMS
//
//  Created by Fafa Van Rooyen on 2026/08/25.
//

