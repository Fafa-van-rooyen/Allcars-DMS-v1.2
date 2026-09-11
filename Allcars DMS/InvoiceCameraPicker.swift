import SwiftUI
import UIKit

struct InvoiceCameraPicker: UIViewControllerRepresentable {

    @Environment(\.dismiss)
    private var dismiss

    let onImageSelected: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onImageSelected: onImageSelected,
            dismiss: dismiss
        )
    }

    func makeUIViewController(
        context: Context
    ) -> UIImagePickerController {

        let picker = UIImagePickerController()

        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo

        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {
    }

    final class Coordinator:
        NSObject,
        UIImagePickerControllerDelegate,
        UINavigationControllerDelegate {

        let onImageSelected: (UIImage) -> Void
        let dismiss: DismissAction

        init(
            onImageSelected: @escaping (UIImage) -> Void,
            dismiss: DismissAction
        ) {
            self.onImageSelected = onImageSelected
            self.dismiss = dismiss
        }

        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) {
            dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info:
                [UIImagePickerController.InfoKey: Any]
        ) {

            guard let image =
                    info[.originalImage] as? UIImage else {

                dismiss()
                return
            }

            onImageSelected(image)
            dismiss()
        }
    }
}//
//  InvoiceCameraPicker.swift
//  Allcars DMS
//
//  Created by Fafa Van Rooyen on 2026/08/23.
//

