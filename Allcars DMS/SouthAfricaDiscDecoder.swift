import Foundation

struct LocalDiscVehicle {

    var registrationNumber: String?
    var vin: String?

    var make: String?
    var model: String?

    var engineNumber: String?

    var colour: String?
    var vehicleClass: String?

    var expiryDate: String?
}

enum SouthAfricanDiscDecoder {

    static func decode(
        _ payload: String
    ) -> LocalDiscVehicle {

        let cleaned =
            payload
                .replacingOccurrences(
                    of: "\0",
                    with: ""
                )
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let fields =
            cleaned
                .components(
                    separatedBy: "%"
                )
                .filter {
                    !$0.isEmpty
                }

        var result =
            LocalDiscVehicle()

        // Registration
        if fields.indices.contains(5) {

            let value =
                clean(fields[5])

            if !value.isEmpty {
                result.registrationNumber =
                    value.uppercased()
            }
        }

        // Vehicle class
        if fields.indices.contains(7) {

            let value =
                clean(fields[7])

            if !value.isEmpty {
                result.vehicleClass = value
            }
        }

        // Make
        if fields.indices.contains(8) {

            let value =
                clean(fields[8])

            if !value.isEmpty {
                result.make = value
            }
        }

        // Model
        if fields.indices.contains(9) {

            let value =
                clean(fields[9])

            if !value.isEmpty {
                result.model = value
            }
        }

        // Colour
        if fields.indices.contains(10) {

            let value =
                cleanColour(
                    fields[10]
                )

            if !value.isEmpty {
                result.colour = value
            }
        }

        // VIN
        if fields.indices.contains(11) {

            let value =
                clean(fields[11])
                    .uppercased()

            if looksLikeVIN(value) {
                result.vin = value
            }
        }

        // Engine Number
        if fields.indices.contains(12) {

            let value =
                clean(fields[12])
                    .uppercased()

            if !value.isEmpty {
                result.engineNumber = value
            }
        }

        // Expiry Date
        if fields.indices.contains(13) {

            let value =
                clean(fields[13])

            if looksLikeDate(value) {
                result.expiryDate = value
            }
        }

        print("")
        print("LOCAL DISC RESULT")
        print("Registration:", result.registrationNumber ?? "nil")
        print("VIN:", result.vin ?? "nil")
        print("Make:", result.make ?? "nil")
        print("Model:", result.model ?? "nil")
        print("Engine:", result.engineNumber ?? "nil")
        print("Colour:", result.colour ?? "nil")
        print("Expiry:", result.expiryDate ?? "nil")
        print("")

        return result
    }

    // MARK: - Engine Number

    private static func findEngineNumber(
        in fields: [String],
        vin: String?
    ) -> String? {

        /*
         On the sample South African MVL payload,
         extra identifiers appear around the VIN.

         Rather than blindly taking one fixed field,
         search the likely region after the VIN.
        */

        let startIndex = 12

        guard fields.count > startIndex else {
            return nil
        }

        for index in startIndex..<fields.count {

            let candidate =
                clean(fields[index])
                    .uppercased()

            if candidate.isEmpty {
                continue
            }

            if candidate == vin {
                continue
            }

            if looksLikeDate(candidate) {
                continue
            }

            if looksLikeEngineNumber(candidate) {
                return candidate
            }
        }

        return nil
    }

    private static func looksLikeEngineNumber(
        _ value: String
    ) -> Bool {

        /*
         Engine numbers vary significantly
         between manufacturers.

         Require:
         - at least 5 characters
         - not too long
         - only letters/numbers
         - at least one number
         */

        guard value.count >= 5,
              value.count <= 20 else {

            return false
        }

        let allowed =
            CharacterSet.alphanumerics

        guard value
            .unicodeScalars
            .allSatisfy({
                allowed.contains($0)
            }) else {

            return false
        }

        let hasNumber =
            value.contains {
                $0.isNumber
            }

        guard hasNumber else {
            return false
        }

        /*
         Avoid treating simple internal
         numeric fields as an engine number.
        */

        let letters =
            value.filter {
                $0.isLetter
            }

        let numbers =
            value.filter {
                $0.isNumber
            }

        if letters.isEmpty &&
            numbers.count <= 8 {

            return false
        }

        return true
    }

    // MARK: - Helpers

    private static func clean(
        _ value: String
    ) -> String {

        value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private static func cleanColour(
        _ value: String
    ) -> String {

        let cleaned =
            clean(value)

        if let slash =
            cleaned.firstIndex(
                of: "/"
            ) {

            return String(
                cleaned[..<slash]
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        }

        return cleaned
    }

    private static func looksLikeVIN(
        _ value: String
    ) -> Bool {

        guard value.count == 17 else {
            return false
        }

        let allowed =
            CharacterSet(
                charactersIn:
                    "ABCDEFGHJKLMNPRSTUVWXYZ0123456789"
            )

        return value
            .unicodeScalars
            .allSatisfy {
                allowed.contains($0)
            }
    }

    private static func looksLikeDate(
        _ value: String
    ) -> Bool {

        let pattern =
            #"^\d{4}-\d{2}-\d{2}$"#

        return value.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }
}
