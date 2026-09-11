import SwiftUI
import CoreData
import UIKit

struct VehicleDetailView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var vehicle: Vehicle

    @State private var showingRecon = false
    @State private var showingSellVehicle = false
    @State private var showingQuote = false
    @State private var showingEditVehicle = false
    @State private var reconInvoice: ReconInvoicePreview?
    @State private var showingReturnToStockConfirmation = false
    @State private var generatedInvoice: GeneratedInvoice?
    @State private var showingInvoiceError = false
    @State private var invoiceErrorMessage = ""

    private let statuses = [
        "Purchased",
        "Awaiting Recon",
        "In Recon",
        "Ready for Sale",
        "Advertised",
        "Reserved",
        "Sold"
    ]

    var body: some View {
        List {
            headerSection
            VehiclePhotoSection(vehicle: vehicle)
            marketingSection
            saleSection
            costingSection
            reconSection
            sellerSection
            vehicleDetailsSection
        }
        .navigationTitle(vehicle.registrationNumber ?? "Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingRecon) {
            AddReconView(vehicle: vehicle)
        }
        .sheet(isPresented: $showingSellVehicle) {
            SellVehicleView(vehicle: vehicle)
        }
        .sheet(isPresented: $showingQuote) {
            QuoteView(vehicle: vehicle)
        }
        .sheet(isPresented: $showingEditVehicle) {
            EditVehicleView(vehicle: vehicle)
        }
        .sheet(item: $reconInvoice) { preview in
            ReconInvoiceImageView(image: preview.image)
        }
        .sheet(item: $generatedInvoice) { invoice in
            InvoicePreviewView(invoiceURL: invoice.url)
        }
        .alert(
            "Could Not Generate Invoice",
            isPresented: $showingInvoiceError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(invoiceErrorMessage)
        }
        .alert(
            "Return Vehicle to Stock?",
            isPresented: $showingReturnToStockConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Return to Stock") { returnToStock() }
        } message: {
            Text("The saved sale and buyer details will be cleared. The vehicle and its purchase and recon history will remain.")
        }
    }

    private var marketingSection: some View {
        Section("Marketing") {
            Button {
                showingQuote = true
            } label: {
                Label("Generate Quote", systemImage: "doc.text")
            }
            .disabled(vehicle.isSold)
        }
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text(vehicle.displayName)
                    .font(.title2.bold())

                Text(vehicle.registrationNumber ?? "No registration")
                    .foregroundStyle(.secondary)

                if let vin = vehicle.vin, !vin.isEmpty {
                    Text(vin)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Picker("Status", selection: statusBinding) {
                ForEach(statuses, id: \.self) { status in
                    Text(status).tag(status)
                }
            }
        }
    }

    private var saleSection: some View {
        Section("Sale") {
            if isSold {
                Label("Vehicle Sold", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                moneyRow(
                    title: "Sale Price",
                    cents: vehicle.salePriceCents
                )

                moneyRow(
                    title: "Actual Profit",
                    cents: vehicle.actualProfitCents,
                    bold: true
                )

                if let date = vehicle.saleDate {
                    LabeledContent(
                        "Sale Date",
                        value: date.formatted(date: .long, time: .omitted)
                    )
                }

                if !buyerName.isEmpty {
                    LabeledContent("Buyer", value: buyerName)
                }

                if let phone = vehicle.buyerPhone, !phone.isEmpty {
                    LabeledContent("Buyer Phone", value: phone)
                }

                Button {
                    showingSellVehicle = true
                } label: {
                    Label("Edit Sale Details", systemImage: "pencil")
                }

                Button {
                    generateInvoice()
                } label: {
                    Label("Generate Invoice", systemImage: "doc.text.fill")
                }

                Button(role: .destructive) {
                    showingReturnToStockConfirmation = true
                } label: {
                    Label("Return to Stock", systemImage: "arrow.uturn.backward.circle")
                }
            } else {
                Button {
                    showingSellVehicle = true
                } label: {
                    Label("Sell Vehicle", systemImage: "banknote.fill")
                }
            }
        }
    }

    private var costingSection: some View {
        Section("Costing") {
            moneyRow(
                title: "Purchase Price",
                cents: vehicle.purchasePriceCents
            )

            moneyRow(title: "Recon", cents: vehicle.reconTotalCents)

            moneyRow(
                title: "Total Cost",
                cents: vehicle.totalCostCents,
                bold: true
            )

            moneyRow(
                title: "Asking Price",
                cents: vehicle.askingPriceCents
            )

            moneyRow(
                title: "Potential Profit",
                cents: vehicle.potentialProfitCents,
                bold: true
            )
        }
    }

    private var reconSection: some View {
        Section("Recon") {
            Button {
                showingRecon = true
            } label: {
                Label("Add Recon Cost", systemImage: "plus.circle.fill")
            }

            if vehicle.reconArray.isEmpty {
                Text("No recon costs added yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vehicle.reconArray, id: \.objectID) { item in
                    reconCard(item)
                }
            }
        }
    }

    private var sellerSection: some View {
        Section("Seller") {
            let name = [vehicle.sellerFirstNames, vehicle.sellerSurname]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            if !name.isEmpty {
                LabeledContent("Seller", value: name)
            }

            if !vehicle.maskedSellerID.isEmpty {
                LabeledContent("ID Number", value: vehicle.maskedSellerID)
            }

            if let phone = vehicle.sellerPhone, !phone.isEmpty {
                LabeledContent("Phone", value: phone)
            }

            if name.isEmpty,
               vehicle.maskedSellerID.isEmpty,
               (vehicle.sellerPhone ?? "").isEmpty {
                Text("No seller details available.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var vehicleDetailsSection: some View {
        Section("Vehicle Details") {
            Button {
                showingEditVehicle = true
            } label: {
                Label("Edit Vehicle Details", systemImage: "pencil")
            }

            LabeledContent(
                "Registration",
                value: vehicle.registrationNumber ?? "-"
            )
            LabeledContent("VIN", value: vehicle.vin ?? "-")
            LabeledContent(
                "Engine Number",
                value: vehicle.engineNumber ?? "-"
            )
            LabeledContent("Colour", value: vehicle.colour ?? "-")
            LabeledContent("Mileage", value: "\(vehicle.mileage) km")
            LabeledContent(
                "Stock Number",
                value: vehicle.stockNumber ?? "-"
            )
        }
    }

    @ViewBuilder
    private func reconCard(_ item: ReconItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.category ?? "Recon")
                        .font(.headline)

                    if let details = item.details, !details.isEmpty {
                        Text(details)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let supplier = item.supplier, !supplier.isEmpty {
                        Text(supplier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(Money.rand(item.amountCents))
                    .font(.headline)
            }

            if let invoice = item.invoiceNumber, !invoice.isEmpty {
                LabeledContent("Invoice", value: invoice)
                    .font(.caption)
            }

            if let data = item.invoiceImageData,
               let image = UIImage(data: data) {
                Button {
                    reconInvoice = ReconInvoicePreview(image: image)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Label("Open Invoice", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
            }

            Toggle(
                isOn: Binding(
                    get: { item.paid },
                    set: { newValue in
                        item.paid = newValue
                        saveReconChange()
                    }
                )
            ) {
                Label(
                    item.paid ? "Paid" : "Outstanding",
                    systemImage: item.paid
                        ? "checkmark.circle.fill"
                        : "clock.fill"
                )
                .foregroundStyle(item.paid ? .green : .orange)
            }
        }
        .padding(.vertical, 6)
    }

    private var isSold: Bool {
        vehicle.isSold
    }

    private var buyerName: String {
        [vehicle.buyerFirstNames, vehicle.buyerSurname]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private var statusBinding: Binding<String> {
        Binding(
            get: { vehicle.status ?? "Purchased" },
            set: { newValue in
                vehicle.status = newValue
                saveContext(message: "Could not update vehicle status")
            }
        )
    }

    private func generateInvoice() {
        do {
            let url = try InvoiceGenerator.generateInvoice(for: vehicle)

            guard FileManager.default.fileExists(atPath: url.path) else {
                throw InvoicePresentationError.fileNotCreated
            }

            generatedInvoice = GeneratedInvoice(url: url)
        } catch {
            invoiceErrorMessage = error.localizedDescription
            showingInvoiceError = true
            print("Invoice generation failed:", error)
        }
    }

    private func saveReconChange() {
        saveContext(message: "Could not update recon payment")
    }

    private func returnToStock() {
        vehicle.status = "Ready for Sale"
        vehicle.salePriceCents = 0
        vehicle.saleDate = nil
        vehicle.buyerFirstNames = nil
        vehicle.buyerSurname = nil
        vehicle.buyerIDNumber = nil
        vehicle.buyerPhone = nil
        vehicle.buyerAddress = nil
        vehicle.buyerVATNumber = nil
        vehicle.salePaymentMethod = nil
        vehicle.saleNotes = nil
        vehicle.saleComments = nil
        vehicle.preparedBy = nil
        saveContext(message: "Could not return vehicle to stock")
    }

    private func saveContext(message: String) {
        do {
            try viewContext.save()
        } catch {
            print("\(message):", error.localizedDescription)
        }
    }

    @ViewBuilder
    private func moneyRow(
        title: String,
        cents: Int64,
        bold: Bool = false
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(Money.rand(cents))
                .fontWeight(bold ? .bold : .regular)
        }
    }
}

private struct GeneratedInvoice: Identifiable {
    let id = UUID()
    let url: URL
}

private enum InvoicePresentationError: LocalizedError {
    case fileNotCreated

    var errorDescription: String? {
        "The invoice PDF file could not be created."
    }
}

private struct ReconInvoicePreview: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct ReconInvoiceImageView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            .background(Color.black)
            .navigationTitle("Recon Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
