import UIKit

enum QuoteGenerator {
    static func generate(
        for vehicle: Vehicle,
        customerName: String,
        customerPhone: String,
        priceCents: Int64,
        validUntil: Date,
        notes: String
    ) throws -> URL {
        guard priceCents > 0 else { throw QuoteError.invalidPrice }

        let stock = safe(vehicle.stockNumber ?? "Vehicle")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("All-Cars-Quote-\(stock).pdf")
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: page)

        try renderer.writePDF(to: url) { context in
            context.beginPage()
            draw(
                vehicle: vehicle,
                customerName: customerName,
                customerPhone: customerPhone,
                priceCents: priceCents,
                validUntil: validUntil,
                notes: notes,
                page: page
            )
        }
        return url
    }

    private static func draw(
        vehicle: Vehicle,
        customerName: String,
        customerPhone: String,
        priceCents: Int64,
        validUntil: Date,
        notes: String,
        page: CGRect
    ) {
        let margin: CGFloat = 38
        let width = page.width - margin * 2
        let navy = UIColor(red: 0.06, green: 0.13, blue: 0.22, alpha: 1)
        let red = UIColor(red: 0.78, green: 0, blue: 0.04, alpha: 1)
        let pale = UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1)

        if let logo = UIImage(named: "ACLogo") {
            aspectFit(logo, in: CGRect(x: margin, y: 18, width: 180, height: 72))
        }
        drawText(
            "VEHICLE QUOTE",
            in: CGRect(x: 300, y: 35, width: 257, height: 30),
            font: .boldSystemFont(ofSize: 23),
            colour: navy,
            alignment: .right
        )
        drawText(
            "Issued \(date(Date()))  •  Valid until \(date(validUntil))",
            in: CGRect(x: 250, y: 70, width: 307, height: 18),
            font: .systemFont(ofSize: 9),
            colour: .darkGray,
            alignment: .right
        )
        red.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 108, width: page.width, height: 6)).fill()

        var y: CGFloat = 132
        let customer = customerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = customerPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        drawText(
            "Prepared for: \(customer.isEmpty ? "Valued Customer" : customer)\(phone.isEmpty ? "" : "  •  \(phone)")",
            in: CGRect(x: margin, y: y, width: width, height: 22),
            font: .systemFont(ofSize: 11, weight: .semibold),
            colour: navy
        )
        y += 30

        if let data = vehicle.mainPhotoData, let image = UIImage(data: data) {
            UIColor.systemGray6.setFill()
            UIBezierPath(roundedRect: CGRect(x: margin, y: y, width: width, height: 275), cornerRadius: 8).fill()
            aspectFit(image, in: CGRect(x: margin + 4, y: y + 4, width: width - 8, height: 267))
            y += 294
        }

        navy.setFill()
        UIBezierPath(roundedRect: CGRect(x: margin, y: y, width: width, height: 42), cornerRadius: 6).fill()
        drawText(
            vehicle.displayName.isEmpty ? "Vehicle" : vehicle.displayName,
            in: CGRect(x: margin + 14, y: y + 9, width: width - 190, height: 24),
            font: .boldSystemFont(ofSize: 17),
            colour: .white
        )
        drawText(
            Money.rand(priceCents),
            in: CGRect(x: margin + width - 175, y: y + 9, width: 160, height: 24),
            font: .boldSystemFont(ofSize: 17),
            colour: .white,
            alignment: .right
        )
        y += 58

        let details = [
            ("Year", vehicle.year > 0 ? String(vehicle.year) : "-"),
            ("Registration", clean(vehicle.registrationNumber)),
            ("Colour", clean(vehicle.colour)),
            ("Mileage", vehicle.mileage > 0 ? "\(vehicle.mileage) km" : "-"),
            ("VIN", clean(vehicle.vin)),
            ("Stock Number", clean(vehicle.stockNumber))
        ]

        for (index, detail) in details.enumerated() {
            let column = CGFloat(index % 2)
            let row = CGFloat(index / 2)
            let itemWidth = width / 2 - 8
            let x = margin + column * (width / 2 + 8)
            let itemY = y + row * 43
            drawText(detail.0.uppercased(), in: CGRect(x: x, y: itemY, width: itemWidth, height: 12), font: .boldSystemFont(ofSize: 8), colour: .gray)
            drawText(detail.1, in: CGRect(x: x, y: itemY + 13, width: itemWidth, height: 20), font: .systemFont(ofSize: 11), colour: .black)
        }
        y += 135

        pale.setFill()
        UIBezierPath(roundedRect: CGRect(x: margin, y: y, width: width, height: 70), cornerRadius: 7).fill()
        drawText("NOTES", in: CGRect(x: margin + 12, y: y + 10, width: width - 24, height: 12), font: .boldSystemFont(ofSize: 8), colour: navy)
        let cleanedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        drawText(cleanedNotes.isEmpty ? "Subject to availability. Final terms are confirmed on sale." : cleanedNotes, in: CGRect(x: margin + 12, y: y + 25, width: width - 24, height: 35), font: .systemFont(ofSize: 9.5), colour: .darkGray)

        drawText(
            "All Cars  •  01 Monument Road, Oranjesig, Bloemfontein  •  +27 76 308 4554",
            in: CGRect(x: margin, y: page.height - 42, width: width, height: 18),
            font: .systemFont(ofSize: 8.5),
            colour: .gray,
            alignment: .center
        )
    }

    private static func drawText(
        _ value: String,
        in rect: CGRect,
        font: UIFont,
        colour: UIColor,
        alignment: NSTextAlignment = .left
    ) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = .byTruncatingTail
        value.draw(in: rect, withAttributes: [
            .font: font,
            .foregroundColor: colour,
            .paragraphStyle: style
        ])
    }

    private static func aspectFit(_ image: UIImage, in rect: CGRect) {
        let scale = min(rect.width / image.size.width, rect.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        image.draw(in: CGRect(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2,
            width: size.width,
            height: size.height
        ))
    }

    private static func clean(_ value: String?) -> String {
        let result = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? "-" : result
    }

    private static func safe(_ value: String) -> String {
        value.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
    }

    private static func date(_ value: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: value)
    }
}

private enum QuoteError: LocalizedError {
    case invalidPrice
    var errorDescription: String? { "Please enter a valid quoted price." }
}
