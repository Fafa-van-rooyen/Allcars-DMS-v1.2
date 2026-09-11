import UIKit
import Vision
import ImageIO

enum BarcodeDetectorError: LocalizedError {

    case invalidImage
    case barcodeNotFound
    case scanFailed(String)

    var errorDescription: String? {

        switch self {

        case .invalidImage:
            return "The selected photo could not be read."

        case .barcodeNotFound:
            return "No PDF417 barcode was found. Try a clearer photo of the licence disc."

        case .scanFailed(let message):
            return "Barcode scanning failed: \(message)"
        }
    }
}

enum BarcodeDetector {

    @MainActor
    static func detectPDF417(
        in image: UIImage
    ) async throws -> String {

        guard let cgImage = image.cgImage else {
            throw BarcodeDetectorError.invalidImage
        }

        let orientation =
            image.cgImageOrientation

        return try await Task.detached(
            priority: .userInitiated
        ) {

            let request =
                VNDetectBarcodesRequest()

            request.symbologies = [
                .pdf417
            ]

            let handler =
                VNImageRequestHandler(
                    cgImage: cgImage,
                    orientation: orientation,
                    options: [:]
                )

            do {

                try handler.perform([
                    request
                ])

            } catch {

                throw BarcodeDetectorError.scanFailed(
                    error.localizedDescription
                )
            }

            guard
                let results = request.results,
                let barcode = results.first(where: {
                    $0.symbology == .pdf417
                }),
                let payload =
                    barcode.payloadStringValue,
                !payload.isEmpty
            else {

                throw BarcodeDetectorError.barcodeNotFound
            }

            return payload
        }.value
    }
}

private extension UIImage {

    var cgImageOrientation:
        CGImagePropertyOrientation {

        switch imageOrientation {

        case .up:
            return .up

        case .down:
            return .down

        case .left:
            return .left

        case .right:
            return .right

        case .upMirrored:
            return .upMirrored

        case .downMirrored:
            return .downMirrored

        case .leftMirrored:
            return .leftMirrored

        case .rightMirrored:
            return .rightMirrored

        @unknown default:
            return .up
        }
    }
}
