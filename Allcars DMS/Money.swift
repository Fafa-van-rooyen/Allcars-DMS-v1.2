import Foundation

enum Money {

    static func cents(from text: String) -> Int64 {

        let cleaned = text
            .replacingOccurrences(of: "R", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let decimal = Decimal(string: cleaned) else {
            return 0
        }

        let number = NSDecimalNumber(decimal: decimal)
        let cents = number.multiplying(by: 100)

        return cents.int64Value
    }

    static func rand(_ cents: Int64) -> String {

        let formatter = NumberFormatter()

        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_ZA")
        formatter.currencyCode = "ZAR"
        formatter.maximumFractionDigits = 2

        let value = Double(cents) / 100.0

        return formatter.string(
            from: NSNumber(value: value)
        ) ?? "R0.00"
    }
}//
//  Money.swift
//  Allcars DMS
//
//  Created by Fafa Van Rooyen on 2026/08/21.
//

