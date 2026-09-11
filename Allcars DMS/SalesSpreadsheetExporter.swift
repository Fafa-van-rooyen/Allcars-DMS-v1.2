import Foundation
import UIKit
import SwiftUI

enum SalesSpreadsheetExporter {
    static func export(_ vehicles: [Vehicle]) throws -> URL {
        let headings = [
            "Sale Date", "Stock Number", "Year", "Make", "Model", "Variant",
            "Registration", "VIN", "Buyer", "Buyer Phone", "Purchase Price",
            "Recon Total", "Recon Outstanding", "Sale Price", "Gross Profit"
        ]
        var rows = [headings]
        let sorted = vehicles.sorted { ($0.saleDate ?? .distantPast) > ($1.saleDate ?? .distantPast) }
        for vehicle in sorted {
            let buyer = [vehicle.buyerFirstNames, vehicle.buyerSurname]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
            rows.append([
                date(vehicle.saleDate), vehicle.stockNumber ?? "",
                vehicle.year == 0 ? "" : String(vehicle.year), vehicle.make ?? "",
                vehicle.model ?? "", vehicle.variant ?? "", vehicle.registrationNumber ?? "",
                vehicle.vin ?? "", buyer, vehicle.buyerPhone ?? "",
                amount(vehicle.purchasePriceCents), amount(vehicle.reconTotalCents),
                amount(vehicle.outstandingReconCents), amount(vehicle.salePriceCents),
                amount(vehicle.actualProfitCents)
            ])
        }
        let csv = rows.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("All-Cars-Sales-\(fileDate(Date())).csv")
        guard let data = csv.data(using: .utf8) else { throw SalesExportError.encodingFailed }
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

private enum SalesExportError: LocalizedError {
    case encodingFailed
    var errorDescription: String? { "The sales spreadsheet could not be created." }
}

struct SalesShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
