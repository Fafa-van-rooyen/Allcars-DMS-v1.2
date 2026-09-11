import Foundation
import CoreData

extension Vehicle {

    var isSold: Bool {

        let normalizedStatus =
            (status ?? "")
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .lowercased()

        return normalizedStatus == "sold"
            || salePriceCents > 0
    }

    var outstandingReconCents: Int64 {

        reconArray.reduce(
            into: Int64(0)
        ) { total, item in

            if !item.paid {
                total += item.amountCents
            }
        }
    }

    var hasOutstandingRecon: Bool {

        reconArray.contains {
            !$0.paid
        }
    }
    var displayName: String {
        let vehicleMake = make ?? ""
        let vehicleModel = model ?? ""
        let vehicleVariant = variant ?? ""

        return "\(vehicleMake) \(vehicleModel) \(vehicleVariant)"
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var reconArray: [ReconItem] {
        let items = reconItems as? Set<ReconItem> ?? []

        return items.sorted {
            ($0.createdAt ?? .distantPast) >
            ($1.createdAt ?? .distantPast)
        }
    }

    var reconTotalCents: Int64 {
        reconArray.reduce(Int64(0)) { total, item in
            total + item.amountCents
        }
    }

    var totalCostCents: Int64 {
        purchasePriceCents + reconTotalCents
    }

    var potentialProfitCents: Int64 {
        askingPriceCents - totalCostCents
    }

    var actualProfitCents: Int64 {

        guard salePriceCents > 0 else {
            return 0
        }

        return salePriceCents - totalCostCents
    }

    var maskedSellerID: String {
        guard let id = sellerIDNumber,
              id.count >= 8 else {
            return ""
        }

        return String(id.prefix(6))
            + "•••••"
            + String(id.suffix(2))
    }
}
