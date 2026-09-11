import Foundation

enum VehicleDiscDecoderError: LocalizedError {

    case invalidURL
    case invalidResponse
    case serverError(String)
    case decodingFailed

    var errorDescription: String? {

        switch self {

        case .invalidURL:
            return "The vehicle decoder URL is invalid."

        case .invalidResponse:
            return "The vehicle decoder returned an invalid response."

        case .serverError(let message):
            return message

        case .decodingFailed:
            return "The vehicle information could not be decoded."
        }
    }
}

struct VehicleDiscDecoder {

    // MARK: CHANGED 

    private static let decoderURLString =
        "http://192.168.2.25:3000/api/vehicle-disc"

    static func decode(
        payload: String
    ) async throws -> DecodedVehicle {

        guard let url =
                URL(string: decoderURLString) else {

            throw VehicleDiscDecoderError.invalidURL
        }

        var request =
            URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        let body = VehicleDiscRequest(
            barcodePayload: payload
        )

        request.httpBody =
            try JSONEncoder().encode(body)

        let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let httpResponse =
                response as? HTTPURLResponse else {

            throw VehicleDiscDecoderError.invalidResponse
        }

        guard
            (200...299).contains(
                httpResponse.statusCode
            )
        else {

            if let errorResponse =
                try? JSONDecoder().decode(
                    ServerErrorResponse.self,
                    from: data
                ) {

                throw VehicleDiscDecoderError.serverError(
                    errorResponse.error
                )
            }

            throw VehicleDiscDecoderError.serverError(
                "Vehicle disc decoding failed."
            )
        }

        guard let result =
                try? JSONDecoder().decode(
                    DecodedVehicle.self,
                    from: data
                )
        else {

            print(
                String(
                    data: data,
                    encoding: .utf8
                ) ?? "No response data"
            )

            throw VehicleDiscDecoderError.decodingFailed
        }

        return result
    }
}

// MARK: - Request

private struct VehicleDiscRequest: Codable {

    let barcodePayload: String
}

// MARK: - Error Response

private struct ServerErrorResponse: Codable {

    let error: String
}

//  VehichleDiscDecoder.swift
//  Allcars DMS
//
//  Created by Fafa Van Rooyen on 2026/08/22.
//

