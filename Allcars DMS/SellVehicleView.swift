import SwiftUI
import CoreData

struct SellVehicleView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var vehicle: Vehicle

    @State private var salePrice = ""
    @State private var saleDate = Date()

    @State private var buyerFirstNames = ""
    @State private var buyerSurname = ""
    @State private var buyerIDNumber = ""
    @State private var buyerPhone = ""
    @State private var buyerAddress = ""
    @State private var buyerVATNumber = ""

    @State private var salePaymentMethod = "EFT"
    @State private var saleNotes = ""
    @State private var saleComments = ""
    @State private var preparedBy = ""
    @State private var mmCode = ""

    @State private var showingIDCameraScanner = false
    @State private var showingIDPhotoScanner = false
    @State private var idScanMessage = ""

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var hasLoadedValues = false

    private let standardPaymentMethods = [
        "EFT",
        "Cash",
        "Finance",
        "Trade-In",
        "Card",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                vehicleSection
                saleSection
                buyerSection
                additionalDetailsSection
                saveSection
            }
            .navigationTitle(isExistingSale ? "Edit Sale" : "Sell Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isExistingSale ? "Update" : "Save") {
                        saveSale()
                    }
                    .disabled(parsedSalePriceCents <= 0)
                }
            }
            .sheet(isPresented: $showingIDCameraScanner) {
                IDCameraScanner { payload in
                    handleIDPayload(payload)
                }
            }
            .sheet(isPresented: $showingIDPhotoScanner) {
                IDPhotoPicker { payload in
                    handleIDPayload(payload)
                }
            }
            .alert("Could Not Save Sale", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadExistingValues()
            }
        }
    }

    private var vehicleSection: some View {
        Section("Vehicle") {
            LabeledContent("Vehicle", value: vehicle.displayName)
            LabeledContent(
                "Registration",
                value: nonEmpty(vehicle.registrationNumber) ?? "-"
            )
            LabeledContent(
                "Total Cost",
                value: Money.rand(vehicle.totalCostCents)
            )
        }
    }

    private var saleSection: some View {
        Section("Sale") {
            TextField("Sale Price", text: $salePrice)
                .keyboardType(.decimalPad)

            DatePicker(
                "Sale Date",
                selection: $saleDate,
                displayedComponents: .date
            )

            Picker("Payment Method", selection: $salePaymentMethod) {
                ForEach(paymentMethods, id: \.self) { method in
                    Text(method).tag(method)
                }
            }

            TextField("M&M Code", text: $mmCode)
                .textInputAutocapitalization(.characters)

            HStack {
                Text("Profit")
                Spacer()
                Text(Money.rand(calculatedProfitCents))
                    .fontWeight(.semibold)
                    .foregroundStyle(calculatedProfitCents >= 0 ? .green : .red)
            }
        }
    }

    private var buyerSection: some View {
        Section("Buyer") {
            Button {
                showingIDCameraScanner = true
            } label: {
                Label("Scan South African ID", systemImage: "person.text.rectangle")
            }

            Button {
                showingIDPhotoScanner = true
            } label: {
                Label("Choose ID Photo", systemImage: "photo.on.rectangle")
            }

            if !idScanMessage.isEmpty {
                Text(idScanMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextField("First Names", text: $buyerFirstNames)
                .textContentType(.givenName)

            TextField("Surname", text: $buyerSurname)
                .textContentType(.familyName)

            TextField("ID Number", text: $buyerIDNumber)
                .keyboardType(.numberPad)

            TextField("Cellphone", text: $buyerPhone)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)

            TextField("Address", text: $buyerAddress, axis: .vertical)
                .lineLimit(2...4)
                .textContentType(.fullStreetAddress)

            TextField("VAT Number (Optional)", text: $buyerVATNumber)
                .keyboardType(.numbersAndPunctuation)
        }
    }

    private var additionalDetailsSection: some View {
        Section("Additional Details") {
            TextField("Prepared By", text: $preparedBy)

            VStack(alignment: .leading, spacing: 8) {
                Text("Comments / Special Instructions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $saleComments)
                    .frame(minHeight: 80)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Internal Notes (Optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $saleNotes)
                    .frame(minHeight: 80)
            }
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                saveSale()
            } label: {
                Label(
                    isExistingSale ? "Update Sale Details" : "Complete Sale",
                    systemImage: isExistingSale ? "square.and.pencil" : "checkmark.circle.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .disabled(parsedSalePriceCents <= 0)
        } footer: {
            Text("Saving marks this vehicle as Sold. You can reopen this screen later to update the sale details.")
        }
    }

    private var isExistingSale: Bool {
        vehicle.status == "Sold" || vehicle.salePriceCents > 0
    }

    private var paymentMethods: [String] {
        let current = cleaned(salePaymentMethod)
        guard !current.isEmpty,
              !standardPaymentMethods.contains(current) else {
            return standardPaymentMethods
        }
        return standardPaymentMethods + [current]
    }

    private var parsedSalePriceCents: Int64 {
        Money.cents(from: salePrice)
    }

    private var calculatedProfitCents: Int64 {
        parsedSalePriceCents - vehicle.totalCostCents
    }

    private func loadExistingValues() {
        guard !hasLoadedValues else { return }
        hasLoadedValues = true

        if vehicle.salePriceCents > 0 {
            salePrice = String(
                format: "%.2f",
                Double(vehicle.salePriceCents) / 100.0
            )
        }

        saleDate = vehicle.saleDate ?? Date()
        buyerFirstNames = vehicle.buyerFirstNames ?? ""
        buyerSurname = vehicle.buyerSurname ?? ""
        buyerIDNumber = vehicle.buyerIDNumber ?? ""
        buyerPhone = vehicle.buyerPhone ?? ""
        buyerAddress = vehicle.buyerAddress ?? ""
        buyerVATNumber = vehicle.buyerVATNumber ?? ""
        saleNotes = vehicle.saleNotes ?? ""
        saleComments = vehicle.saleComments ?? ""
        preparedBy = vehicle.preparedBy ?? ""
        mmCode = vehicle.mmCode ?? ""

        if let existingMethod = nonEmpty(vehicle.salePaymentMethod) {
            salePaymentMethod = existingMethod
        }
    }

    private func handleIDPayload(_ payload: String) {
        let result = SouthAfricanIDDecoder.decode(payload)
        var foundData = false

        if let value = nonEmpty(result.firstNames) {
            buyerFirstNames = value
            foundData = true
        }

        if let value = nonEmpty(result.surname) {
            buyerSurname = value
            foundData = true
        }

        if let value = nonEmpty(result.idNumber) {
            buyerIDNumber = value
            foundData = true
        }

        idScanMessage = foundData
            ? "Buyer ID information detected."
            : "ID barcode detected, but the local ID format could not be read."
    }

    private func saveSale() {
        let priceCents = parsedSalePriceCents

        guard priceCents > 0 else {
            errorMessage = "Please enter a valid sale price."
            showingError = true
            return
        }

        vehicle.salePriceCents = priceCents
        vehicle.saleDate = saleDate
        vehicle.buyerFirstNames = cleaned(buyerFirstNames)
        vehicle.buyerSurname = cleaned(buyerSurname)
        vehicle.buyerIDNumber = cleaned(buyerIDNumber)
        vehicle.buyerPhone = cleaned(buyerPhone)
        vehicle.buyerAddress = cleaned(buyerAddress)
        vehicle.buyerVATNumber = cleaned(buyerVATNumber)
        vehicle.salePaymentMethod = cleaned(salePaymentMethod)
        vehicle.saleNotes = cleaned(saleNotes)
        vehicle.saleComments = cleaned(saleComments)
        vehicle.preparedBy = cleaned(preparedBy)
        vehicle.mmCode = cleaned(mmCode).uppercased()
        vehicle.status = "Sold"

        do {
            try viewContext.save()
            dismiss()
        } catch {
            viewContext.rollback()
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func cleaned(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = cleaned(value)
        return trimmed.isEmpty ? nil : trimmed
    }
}

//
//  SellVehicleView.swift
//  Allcars DMS
//
//  Created by Fafa Van Rooyen on 2026/08/24.
//

