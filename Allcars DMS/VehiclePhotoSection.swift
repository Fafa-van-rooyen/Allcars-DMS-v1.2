import SwiftUI
import PhotosUI
import UIKit
import CoreData

struct VehiclePhotoSection: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var vehicle: Vehicle

    @State private var selectedItem: PhotosPickerItem?
    @State private var showingShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        Section("Main Vehicle Photo") {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    showingShareSheet = true
                } label: {
                    Label("Share Photo", systemImage: "square.and.arrow.up")
                }

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Replace Photo", systemImage: "photo.badge.arrow.down")
                }

                Button(role: .destructive) {
                    vehicle.mainPhotoData = nil
                    save()
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Add Main Photo", systemImage: "photo.badge.plus")
                }

                Text("One optimized photo is synchronized and used on the brochure.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: selectedItem) {
            await importSelectedPhoto()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image {
                VehiclePhotoActivityView(activityItems: [image])
            }
        }
        .alert(
            "Could Not Save Photo",
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

    private var image: UIImage? {
        guard let data = vehicle.mainPhotoData else { return nil }
        return UIImage(data: data)
    }

    private func importSelectedPhoto() async {
        guard let selectedItem else { return }
        do {
            guard let data = try await selectedItem.loadTransferable(type: Data.self),
                  let source = UIImage(data: data),
                  let compressed = source.brochureJPEGData() else {
                throw VehiclePhotoError.invalidImage
            }
            vehicle.mainPhotoData = compressed
            try viewContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
        self.selectedItem = nil
    }

    private func save() {
        do { try viewContext.save() }
        catch { errorMessage = error.localizedDescription }
    }
}

private extension UIImage {
    func brochureJPEGData() -> Data? {
        let longestSide: CGFloat = 1800
        let scale = min(1, longestSide / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.78)
    }
}

private struct VehiclePhotoActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

private enum VehiclePhotoError: LocalizedError {
    case invalidImage
    var errorDescription: String? { "The selected photo could not be read." }
}
