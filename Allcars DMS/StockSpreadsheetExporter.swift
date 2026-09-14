import Foundation

enum StockSpreadsheetExporter {
    static func export(_ vehicles: [Vehicle]) throws -> URL {
        let headings = [
            "Stock Number", "Year", "Make", "Model", "Variant", "Registration",
            "VIN", "Engine Number", "Colour", "Mileage", "Purchase Date",
            "Purchase Price", "Recon Total", "Recon Outstanding", "Total Cost",
            "Asking Price", "Potential Profit", "Status"
        ]
        var rows = [headings]
        let sorted = vehicles.sorted {
            ($0.stockNumber ?? "") < ($1.stockNumber ?? "")
        }
        for vehicle in sorted {
            rows.append([
                vehicle.stockNumber ?? "",
                vehicle.year == 0 ? "" : String(vehicle.year),
                vehicle.make ?? "", vehicle.model ?? "", vehicle.variant ?? "",
                vehicle.registrationNumber ?? "", vehicle.vin ?? "",
                vehicle.engineNumber ?? "", vehicle.colour ?? "",
                vehicle.mileage == 0 ? "" : String(vehicle.mileage),
                date(vehicle.purchaseDate), amount(vehicle.purchasePriceCents),
                amount(vehicle.reconTotalCents), amount(vehicle.outstandingReconCents),
                amount(vehicle.totalCostCents), amount(vehicle.askingPriceCents),
                amount(vehicle.potentialProfitCents), vehicle.status ?? ""
            ])
        }
        let csv = rows.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("All-Cars-Stock-\(fileDate(Date())).csv")
        guard let data = csv.data(using: .utf8) else { throw StockExportError.encodingFailed }
        try data.write(to: url, options: .atomic)
        return url
    }

    nonisolated private static func escape(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
    private static func amount(_ cents: Int64) -> String {
        String(format: "%.2f", Double(cents) / 100)
    }
    private static func date(_ value: Date?) -> String {
        guard let value else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_ZA")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: value)
    }
    private static func fileDate(_ value: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: value)
    }
}

private enum StockExportError: LocalizedError {
    case encodingFailed
    var errorDescription: String? { "The stock spreadsheet could not be created." }
}
