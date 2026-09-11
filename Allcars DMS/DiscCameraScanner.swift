import SwiftUI
import VisionKit
import Vision

struct DiscCameraScanner: UIViewControllerRepresentable {

    @Environment(\.dismiss)
    private var dismiss

    let onResult: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onResult: onResult,
            dismiss: dismiss
        )
    }

    func makeUIViewController(
        context: Context
    ) -> UIViewController {

        guard DataScannerViewController.isSupported,
              DataScannerViewController.isAvailable else {

            let controller = UIViewController()

            let label = UILabel()
            label.text =
                "Live barcode scanning is not available on this device."
            label.numberOfLines = 0
            label.textAlignment = .center

            label.translatesAutoresizingMaskIntoConstraints = false

            controller.view.addSubview(label)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(
                    equalTo: controller.view.centerXAnchor
                ),
                label.centerYAnchor.constraint(
                    equalTo: controller.view.centerYAnchor
                ),
                label.leadingAnchor.constraint(
                    greaterThanOrEqualTo:
                        controller.view.leadingAnchor,
                    constant: 30
                ),
                label.trailingAnchor.constraint(
                    lessThanOrEqualTo:
                        controller.view.trailingAnchor,
                    constant: -30
                )
            ])

            return controller
        }

        let scanner =
            DataScannerViewController(
                recognizedDataTypes: [
                    .barcode(
                        symbologies: [
                            .pdf417
                        ]
                    )
                ],
                qualityLevel: .accurate,
                recognizesMultipleItems: false,
                isHighFrameRateTrackingEnabled: false,
                isPinchToZoomEnabled: true,
                isGuidanceEnabled: true,
                isHighlightingEnabled: true
            )

        scanner.delegate = context.coordinator

        do {
            try scanner.startScanning()
        } catch {
            print(
                "Could not start scanner:",
                error.localizedDescription
            )
        }

        return scanner
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {}

    static func dismantleUIViewController(
        _ uiViewController: UIViewController,
        coordinator: Coordinator
    ) {

        if let scanner =
            uiViewController as? DataScannerViewController {

            scanner.stopScanning()
        }
    }

    final class Coordinator:
        NSObject,
        DataScannerViewControllerDelegate {

        let onResult: (String) -> Void
        let dismiss: DismissAction

        private var hasReturnedResult = false

        init(
            onResult: @escaping (String) -> Void,
            dismiss: DismissAction
        ) {

            self.onResult = onResult
            self.dismiss = dismiss
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {

            guard !hasReturnedResult else {
                return
            }

            for item in addedItems {

                guard case
                    .barcode(let barcode) = item
                else {
                    continue
                }

                guard
                    barcode.observation.symbology ==
                        .pdf417,
                    let payload =
                        barcode.observation
                            .payloadStringValue,
                    !payload.isEmpty
                else {
                    continue
                }

                hasReturnedResult = true

                dataScanner.stopScanning()

                onResult(payload)

                dismiss()

                return
            }
        }
    }
}
