import SwiftUI
import CoreData

struct AddVehicleView: View {

    @Environment(\.managedObjectContext)
    private var viewContext

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Vehicle Details

    @State private var make = ""
    @State private var model = ""
    @State private var variant = ""
    @State private var year = ""
    @State private var registration = ""
    @State private var vin = ""
    @State private var engineNumber = ""
    @State private var colour = ""
    @State private var mileage = ""

    // MARK: - Purchase Details

    @State private var purchasePrice = ""
    @State private var askingPrice = ""

    // MARK: - Seller Details

    @State private var sellerFirstNames = ""
    @State private var sellerSurname = ""
    @State private var sellerID = ""
    @State private var sellerPhone = ""

    // MARK: - Licence Disc Scanner

    @State private var showingCameraScanner = false
    @State private var showingPhotoScanner = false

    @State private var discPayload = ""
    @State private var scanMessage = ""
    @State private var scannerError: String?

    // MARK: - ID Scanner

    @State private var showingIDCameraScanner = false
    @State private var showingIDPhotoScanner = false
    @State private var idScanMessage = ""

    var body: some View {

        NavigationStack {

            Form {

                licenceDiscSection

                vehicleSection

                purchaseSection

                sellerSection
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("Save") {
                        saveVehicle()
                    }
                    .disabled(
                        make.isEmpty &&
                        model.isEmpty &&
                        registration.isEmpty &&
                        vin.isEmpty
                    )
                }
            }

            // MARK: - Licence Disc Camera

            .sheet(
                isPresented: $showingCameraScanner
            ) {

                DiscCameraScanner { payload in
                    handleDiscPayload(payload)
                }
            }

            // MARK: - Licence Disc Photos

            .sheet(
                isPresented: $showingPhotoScanner
            ) {

                DiscPhotoPicker { payload in
                    handleDiscPayload(payload)
                }
            }

            // MARK: - ID Camera

            .sheet(
                isPresented: $showingIDCameraScanner
            ) {

                IDCameraScanner { payload in
                    handleIDPayload(payload)
                }
            }

            // MARK: - ID Photos

            .sheet(
                isPresented: $showingIDPhotoScanner
            ) {

                IDPhotoPicker { payload in
                    handleIDPayload(payload)
                }
            }
        }
    }

    // MARK: - Licence Disc Section

    private var licenceDiscSection: some View {

        Section("Licence Disc") {

            Button {
                showingCameraScanner = true
            } label: {

                Label(
                    "Scan Disc with Camera",
                    systemImage: "barcode.viewfinder"
                )
                .font(.headline)
            }

            Button {
                showingPhotoScanner = true
            } label: {

                Label(
                    "Choose Disc Photo",
                    systemImage: "photo.on.rectangle"
                )
            }

            if !discPayload.isEmpty {

                Label(
                    "Licence disc barcode detected",
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(.green)
            }

            if !scanMessage.isEmpty {

                Text(scanMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let scannerError {

                Text(scannerError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Vehicle Section

    private var vehicleSection: some View {

        Section("Vehicle") {

            TextField(
                "Make",
                text: $make
            )

            TextField(
                "Model",
                text: $model
            )

            TextField(
                "Variant",
                text: $variant
            )

            TextField(
                "Year",
                text: $year
            )
            .keyboardType(.numberPad)

            TextField(
                "Registration",
                text: $registration
            )
            .textInputAutocapitalization(.characters)

            TextField(
                "VIN",
                text: $vin
            )
            .textInputAutocapitalization(.characters)

            TextField(
                "Engine Number",
                text: $engineNumber
            )
            .textInputAutocapitalization(.characters)

            TextField(
                "Colour",
                text: $colour
            )

            TextField(
                "Mileage",
                text: $mileage
            )
            .keyboardType(.numberPad)
        }
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {

        Section("Purchase") {

            TextField(
                "Purchase Price",
                text: $purchasePrice
            )
            .keyboardType(.decimalPad)

            TextField(
                "Asking Price",
                text: $askingPrice
            )
            .keyboardType(.decimalPad)
        }
    }

    // MARK: - Seller Section

    private var sellerSection: some View {

        Section("Seller") {

            Button {
                showingIDCameraScanner = true
            } label: {

                Label(
                    "Scan South African ID",
                    systemImage: "person.text.rectangle"
                )
            }

            Button {
                showingIDPhotoScanner = true
            } label: {

                Label(
                    "Choose ID Photo",
                    systemImage: "photo.on.rectangle"
                )
            }

            if !idScanMessage.isEmpty {

                Text(idScanMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextField(
                "First Names",
                text: $sellerFirstNames
            )

            TextField(
                "Surname",
                text: $sellerSurname
            )

            TextField(
                "ID Number",
                text: $sellerID
            )
            .keyboardType(.numberPad)

            TextField(
                "Cellphone",
                text: $sellerPhone
            )
            .keyboardType(.phonePad)
        }
    }

    // MARK: - Handle Licence Disc

    private func handleDiscPayload(
        _ payload: String
    ) {

        discPayload = payload
        scannerError = nil

        scanMessage =
            "Licence disc detected. Reading locally..."

        let localVehicle =
            SouthAfricanDiscDecoder.decode(
                payload
            )

        applyLocalVehicle(
            localVehicle
        )

        let foundLocalData =
            !registration.isEmpty ||
            !vin.isEmpty ||
            !make.isEmpty ||
            !model.isEmpty ||
            !engineNumber.isEmpty ||
            !colour.isEmpty

        if foundLocalData {

            scanMessage =
                "Vehicle information read directly from licence disc."

        } else {

            scanMessage =
                "Barcode detected, but the local decoder could not read the vehicle information."

            scannerError =
                "This licence-disc format still needs to be mapped."
        }
    }

    // MARK: - Apply Vehicle Data

    @MainActor
    private func applyLocalVehicle(
        _ vehicle: LocalDiscVehicle
    ) {

        if let value = vehicle.registrationNumber,
           !value.isEmpty {

            registration =
                value.uppercased()
        }

        if let value = vehicle.vin,
           !value.isEmpty {

            vin =
                value.uppercased()
        }

        if let value = vehicle.make,
           !value.isEmpty {

            make = value
        }

        if let value = vehicle.model,
           !value.isEmpty {

            model = value
        }

        if let value = vehicle.engineNumber,
           !value.isEmpty {

            engineNumber =
                value.uppercased()
        }

        if let value = vehicle.colour,
           !value.isEmpty {

            colour = value
        }
    }

    // MARK: - Handle SA ID

    private func handleIDPayload(
        _ payload: String
    ) {

        let result =
            SouthAfricanIDDecoder.decode(
                payload
            )

        var foundData = false

        if let firstNames = result.firstNames,
           !firstNames.isEmpty {

            sellerFirstNames = firstNames
            foundData = true
        }

        if let surname = result.surname,
           !surname.isEmpty {

            sellerSurname = surname
            foundData = true
        }

        if let idNumber = result.idNumber,
           !idNumber.isEmpty {

            sellerID = idNumber
            foundData = true
        }

        if foundData {

            idScanMessage =
                "Seller ID information detected."

        } else {

            idScanMessage =
                "ID barcode detected, but the local ID format still needs to be mapped."
        }
    }

    // MARK: - Save Vehicle

    private func saveVehicle() {
        let dealership: Dealership
        do {
            dealership = try PersistenceController.shared.dealership()
        } catch {
            scannerError = error.localizedDescription
            return
        }

        // Resolve the root before inserting the vehicle. dealership() may save
        // setup changes, and an inserted vehicle cannot move stores afterward.
        let vehicle = Vehicle(context: viewContext)

        if let store = dealership.objectID.persistentStore {
            viewContext.assign(vehicle, to: store)
        }
        vehicle.dealership = dealership

        vehicle.id = UUID()
        vehicle.createdAt = Date()

        vehicle.stockNumber =
            "STK-\(UUID().uuidString.prefix(6))"

        vehicle.make =
            make.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        vehicle.model =
            model.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        vehicle.variant =
            variant.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        vehicle.year =
            Int16(year) ?? 0

        vehicle.registrationNumber =
            registration
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()

        vehicle.vin =
            vin
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()

        vehicle.engineNumber =
            engineNumber
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased()

        vehicle.colour =
            colour.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        vehicle.mileage =
            Int64(mileage) ?? 0

        vehicle.purchasePriceCents =
            Money.cents(
                from: purchasePrice
            )

        vehicle.askingPriceCents =
            Money.cents(
                from: askingPrice
            )

        vehicle.purchaseDate =
            Date()

        vehicle.status =
            "Purchased"

        vehicle.sellerFirstNames =
            sellerFirstNames.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        vehicle.sellerSurname =
            sellerSurname.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        vehicle.sellerIDNumber =
            sellerID.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        vehicle.sellerPhone =
            sellerPhone.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        do {

            try viewContext.save()

            dismiss()

        } catch {

            print(
                "Save vehicle failed:",
                error.localizedDescription
            )
        }
    }
}
