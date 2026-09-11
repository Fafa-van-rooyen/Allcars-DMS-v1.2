import UIKit

enum InvoiceGenerator {

    static func generateInvoice(for vehicle: Vehicle) throws -> URL {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let stock = clean(vehicle.stockNumber) == "-" ? "Vehicle" : clean(vehicle.stockNumber)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Tax-Invoice-\(safeFileName(stock)).pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: page)
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            drawInvoice(vehicle, page: page)
        }

        return url
    }

    private static func drawInvoice(_ vehicle: Vehicle, page: CGRect) {
        let margin: CGFloat = 38
        let width = page.width - margin * 2
        let navy = UIColor(red: 0.06, green: 0.13, blue: 0.22, alpha: 1)
        _ = UIColor(red: 0.83, green: 0.62, blue: 0.20, alpha: 1)
        let pale = UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1)
        var y: CGFloat = 0

        // Header. Add the supplied logo to Assets.xcassets as "ACLogo".
        fill(CGRect(x: 0, y: 0, width: page.width, height: 112), colour: .white)

        if let logo = UIImage(named: "ACLogo") {
            drawAspectFit(
                logo,
                in: CGRect(x: margin, y: 15, width: 190, height: 78)
            )
        } else {
            text(
                "ALL CARS",
                rect: CGRect(x: margin, y: 29, width: 260, height: 38),
                font: .boldSystemFont(ofSize: 30),
                colour: navy
            )
        }
        text(
            "TAX INVOICE",
            rect: CGRect(x: 350, y: 34, width: 207, height: 30),
            font: .boldSystemFont(ofSize: 22),
            colour: navy,
            alignment: .right
        )
        text(
            "Date  \(dateString(vehicle.saleDate ?? Date()))",
            rect: CGRect(x: 350, y: 70, width: 207, height: 18),
            font: .systemFont(ofSize: 10),
            colour: .darkGray,
            alignment: .right
        )

        fill(
            CGRect(x: 0, y: 110, width: page.width, height: 6),
            colour: UIColor(red: 0.78, green: 0.00, blue: 0.04, alpha: 1)
        )

        y = 134

        // Dealer details and invoice information
        text(
            "01 Monument Road, Oranjesig\nBloemfontein, 9301\n+27 76 308 4554  |  fafavrooyen@gmail.com",
            rect: CGRect(x: margin, y: y, width: 320, height: 48),
            font: .systemFont(ofSize: 9.5),
            colour: .darkGray
        )
        text(
            "VAT NO. 4890214374\nTRAFFIC REG. 395001DDL0009\nSTOCK NO. \(clean(vehicle.stockNumber))",
            rect: CGRect(x: 350, y: y, width: 207, height: 48),
            font: .systemFont(ofSize: 9.5, weight: .semibold),
            colour: navy,
            alignment: .right
        )

        y = 196
        sectionTitle("BUYER DETAILS", x: margin, y: y, width: width, colour: navy)
        y += 28

        let buyer = [vehicle.buyerFirstNames, vehicle.buyerSurname]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        y = row("Name", buyer.isEmpty ? "-" : buyer, y: y, margin: margin, width: width)
        y = row("ID Number", clean(vehicle.buyerIDNumber), y: y, margin: margin, width: width)
        y = row("Cellphone", clean(vehicle.buyerPhone), y: y, margin: margin, width: width)
        y = row("Address", clean(vehicle.buyerAddress), y: y, margin: margin, width: width, height: 30)
        y = row("VAT Number", clean(vehicle.buyerVATNumber), y: y, margin: margin, width: width)
        y = row("Prepared By", clean(vehicle.preparedBy), y: y, margin: margin, width: width)

        y += 5
        sectionTitle("VEHICLE DETAILS", x: margin, y: y, width: width, colour: navy)
        y += 28

        let model = [vehicle.model, vehicle.variant]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let leftX = margin
        let rightX = margin + width / 2 + 8
        let columnWidth = width / 2 - 8

        labelValue("Year", vehicle.year > 0 ? String(vehicle.year) : "-", x: leftX, y: y, width: columnWidth)
        labelValue("Make", clean(vehicle.make), x: rightX, y: y, width: columnWidth)
        y += 24
        labelValue("Model", model.isEmpty ? "-" : model, x: leftX, y: y, width: columnWidth)
        labelValue("Colour", clean(vehicle.colour), x: rightX, y: y, width: columnWidth)
        y += 24
        labelValue("Registration", clean(vehicle.registrationNumber), x: leftX, y: y, width: columnWidth)
        labelValue("M&M Code", clean(vehicle.mmCode), x: rightX, y: y, width: columnWidth)
        y += 24
        labelValue("Engine Number", clean(vehicle.engineNumber), x: leftX, y: y, width: columnWidth)
        labelValue("VIN", clean(vehicle.vin), x: rightX, y: y, width: columnWidth)
        y += 34

        // Comments
        fill(CGRect(x: margin, y: y, width: width, height: 48), colour: pale, radius: 6)
        text(
            "COMMENTS / SPECIAL INSTRUCTIONS",
            rect: CGRect(x: margin + 10, y: y + 7, width: width - 20, height: 13),
            font: .boldSystemFont(ofSize: 8.5),
            colour: navy
        )
        text(
            clean(vehicle.saleComments),
            rect: CGRect(x: margin + 10, y: y + 23, width: width - 20, height: 20),
            font: .systemFont(ofSize: 9),
            colour: .darkGray
        )
        y += 61

        // Banking and totals
        let bankWidth: CGFloat = 300
        fill(CGRect(x: margin, y: y, width: bankWidth, height: 112), colour: pale, radius: 7)
        text(
            "BANKING DETAILS",
            rect: CGRect(x: margin + 12, y: y + 10, width: bankWidth - 24, height: 16),
            font: .boldSystemFont(ofSize: 11),
            colour: navy
        )
        text(
            "Bank\nAccount Holder\nAccount Number\nBranch Code\nPayment Reference",
            rect: CGRect(x: margin + 12, y: y + 32, width: 105, height: 72),
            font: .systemFont(ofSize: 9, weight: .semibold),
            colour: .darkGray,
            lineSpacing: 3
        )
        text(
            "FNB\nIan Van Rooyen\n62542465407\n230234\n\(vehicle.displayName.isEmpty ? "Vehicle name" : vehicle.displayName)",
            rect: CGRect(x: margin + 120, y: y + 32, width: bankWidth - 132, height: 72),
            font: .systemFont(ofSize: 9),
            colour: .black,
            lineSpacing: 3
        )

        let total = Double(vehicle.salePriceCents) / 100
        let excludingVAT = total / 1.15
        let vat = total - excludingVAT
        let totalsX = margin + bankWidth + 17
        let totalsWidth = width - bankWidth - 17

        amountRow("Subtotal", excludingVAT, x: totalsX, y: y + 4, width: totalsWidth)
        amountRow("VAT @ 15%", vat, x: totalsX, y: y + 34, width: totalsWidth)
        fill(CGRect(x: totalsX, y: y + 65, width: totalsWidth, height: 43), colour: navy, radius: 5)
        text(
            "TOTAL",
            rect: CGRect(x: totalsX + 10, y: y + 77, width: 52, height: 18),
            font: .boldSystemFont(ofSize: 12),
            colour: .white
        )
        text(
            money(total),
            rect: CGRect(x: totalsX + 62, y: y + 75, width: totalsWidth - 72, height: 20),
            font: .boldSystemFont(ofSize: 14),
            colour: .white,
            alignment: .right
        )

        y += 140
        text(
            "BUYER SIGNATURE",
            rect: CGRect(x: margin, y: y, width: 110, height: 15),
            font: .boldSystemFont(ofSize: 8.5),
            colour: .darkGray
        )
        line(x1: margin + 105, x2: margin + 300, y: y + 11, colour: .gray)
        text(
            "NAME",
            rect: CGRect(x: margin + 315, y: y, width: 42, height: 15),
            font: .boldSystemFont(ofSize: 8.5),
            colour: .darkGray
        )
        line(x1: margin + 355, x2: page.width - margin, y: y + 11, colour: .gray)

        text(
            "Thank you for choosing All Cars.",
            rect: CGRect(x: margin, y: page.height - 37, width: width, height: 16),
            font: .systemFont(ofSize: 8.5),
            colour: .gray,
            alignment: .center
        )
    }

    @discardableResult
    private static func row(
        _ label: String,
        _ value: String,
        y: CGFloat,
        margin: CGFloat,
        width: CGFloat,
        height: CGFloat = 20
    ) -> CGFloat {
        text(label.uppercased(), rect: CGRect(x: margin, y: y, width: 115, height: height), font: .boldSystemFont(ofSize: 8.5), colour: .darkGray)
        text(value, rect: CGRect(x: margin + 120, y: y, width: width - 120, height: height), font: .systemFont(ofSize: 9.5), colour: .black)
        line(x1: margin + 120, x2: margin + width, y: y + height - 4, colour: .systemGray4)
        return y + height
    }

    private static func labelValue(_ label: String, _ value: String, x: CGFloat, y: CGFloat, width: CGFloat) {
        text(label.uppercased(), rect: CGRect(x: x, y: y, width: width, height: 11), font: .boldSystemFont(ofSize: 7.5), colour: .gray)
        text(value, rect: CGRect(x: x, y: y + 11, width: width, height: 15), font: .systemFont(ofSize: 9.5), colour: .black)
    }

    private static func sectionTitle(_ title: String, x: CGFloat, y: CGFloat, width: CGFloat, colour: UIColor) {
        fill(CGRect(x: x, y: y, width: width, height: 21), colour: colour, radius: 4)
        text(title, rect: CGRect(x: x + 9, y: y + 5, width: width - 18, height: 13), font: .boldSystemFont(ofSize: 9.5), colour: .white)
    }

    private static func amountRow(_ label: String, _ amount: Double, x: CGFloat, y: CGFloat, width: CGFloat) {
        text(label, rect: CGRect(x: x, y: y, width: 75, height: 18), font: .systemFont(ofSize: 9), colour: .darkGray)
        text(money(amount), rect: CGRect(x: x + 75, y: y, width: width - 75, height: 18), font: .systemFont(ofSize: 10, weight: .semibold), colour: .black, alignment: .right)
        line(x1: x, x2: x + width, y: y + 23, colour: .systemGray4)
    }

    private static func text(
        _ value: String,
        rect: CGRect,
        font: UIFont,
        colour: UIColor,
        alignment: NSTextAlignment = .left,
        lineSpacing: CGFloat = 0
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byTruncatingTail
        paragraph.lineSpacing = lineSpacing
        value.draw(in: rect, withAttributes: [
            .font: font,
            .foregroundColor: colour,
            .paragraphStyle: paragraph
        ])
    }

    private static func fill(_ rect: CGRect, colour: UIColor, radius: CGFloat = 0) {
        colour.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: radius).fill()
    }

    private static func drawAspectFit(_ image: UIImage, in rect: CGRect) {
        guard image.size.width > 0, image.size.height > 0 else { return }

        let scale = min(
            rect.width / image.size.width,
            rect.height / image.size.height
        )
        let size = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let target = CGRect(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        image.draw(in: target)
    }

    private static func line(x1: CGFloat, x2: CGFloat, y: CGFloat, colour: UIColor) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x1, y: y))
        path.addLine(to: CGPoint(x: x2, y: y))
        colour.setStroke()
        path.lineWidth = 0.6
        path.stroke()
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    private static func money(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_ZA")
        formatter.currencyCode = "ZAR"
        formatter.currencySymbol = "R"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "R %.2f", amount)
    }

    private static func clean(_ value: String?) -> String {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "-" : trimmed
    }

    private static func safeFileName(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return value.components(separatedBy: invalid).joined(separator: "-")
    }
}


//
//  InvoiceGenerator.swift
//  Allcars DMS
//
//  Created by Fafa Van Rooyen on 2026/08/25.
//

