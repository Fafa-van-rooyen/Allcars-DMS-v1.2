import SwiftUI
import CoreData

struct EditVehicleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vehicle: Vehicle

    @State private var make = ""
    @State private var model = ""
    @State private var variant = ""
    @State private var year = ""
    @State private var registration = ""
    @State private var vin = ""
    @State private var engineNumber = ""
    @State private var colour = ""
    @State private var mileage = ""
    @State private var purchasePrice = ""
    @State private var askingPrice = ""
    @State private var sellerFirstNames = ""
    @State private var sellerSurname = ""
    @State private var sellerID = ""
    @State private var sellerPhone = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    TextField("Variant", text: $variant)
                    TextField("Year", text: $year).keyboardType(.numberPad)
                    TextField("Registration", text: $registration)
                        .textInputAutocapitalization(.characters)
                    TextField("VIN", text: $vin)
                        .textInputAutocapitalization(.characters)
                    TextField("Engine Number", text: $engineNumber)
                        .textInputAutocapitalization(.characters)
                    TextField("Colour", text: $colour)
                    TextField("Mileage", text: $mileage).keyboardType(.numberPad)
                }

                Section("Pricing") {
                    TextField("Purchase Price", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                    TextField("Asking Price", text: $askingPrice)
                        .keyboardType(.decimalPad)
                }

                Section("Seller") {
                    TextField("First Names", text: $sellerFirstNames)
                    TextField("Surname", text: $sellerSurname)
                    TextField("ID Number", text: $sellerID).keyboardType(.numberPad)
                    TextField("Cellphone", text: $sellerPhone).keyboardType(.phonePad)
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear(perform: load)
            .alert("Could Not Save", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private func load() {
        make = vehicle.make ?? ""
        model = vehicle.model ?? ""
        variant = vehicle.variant ?? ""
        year = vehicle.year == 0 ? "" : String(vehicle.year)
        registration = vehicle.registrationNumber ?? ""
        vin = vehicle.vin ?? ""
        engineNumber = vehicle.engineNumber ?? ""
        colour = vehicle.colour ?? ""
        mileage = vehicle.mileage == 0 ? "" : String(vehicle.mileage)
        purchasePrice = decimal(vehicle.purchasePriceCents)
        askingPrice = decimal(vehicle.askingPriceCents)
        sellerFirstNames = vehicle.sellerFirstNames ?? ""
        sellerSurname = vehicle.sellerSurname ?? ""
        sellerID = vehicle.sellerIDNumber ?? ""
        sellerPhone = vehicle.sellerPhone ?? ""
    }

    private func save() {
        vehicle.make = clean(make)
        vehicle.model = clean(model)
        vehicle.variant = clean(variant)
        vehicle.year = Int16(year) ?? 0
        vehicle.registrationNumber = clean(registration).uppercased()
        vehicle.vin = clean(vin).uppercased()
        vehicle.engineNumber = clean(engineNumber).uppercased()
        vehicle.colour = clean(colour)
        vehicle.mileage = Int64(mileage) ?? 0
        vehicle.purchasePriceCents = Money.cents(from: purchasePrice)
        vehicle.askingPriceCents = Money.cents(from: askingPrice)
        vehicle.sellerFirstNames = clean(sellerFirstNames)
        vehicle.sellerSurname = clean(sellerSurname)
        vehicle.sellerIDNumber = clean(sellerID)
        vehicle.sellerPhone = clean(sellerPhone)

        do {
            try viewContext.save()
            dismiss()
        } catch {
            viewContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decimal(_ cents: Int64) -> String {
        String(format: "%.2f", Double(cents) / 100)
    }
}
