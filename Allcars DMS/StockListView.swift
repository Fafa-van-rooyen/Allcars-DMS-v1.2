import SwiftUI
import CoreData

struct StockListView: View {

    @Environment(\.managedObjectContext)
    private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                keyPath: \Vehicle.createdAt,
                ascending: false
            )
        ],
        animation: .default
    )
    private var vehicles: FetchedResults<Vehicle>

    @State private var showingAddVehicle = false
    @State private var searchText = ""

    @State private var vehicleToDelete: Vehicle?
    @State private var showingDeleteAlert = false
    @State private var exportFile: StockExportFile?
    @State private var exportError: String?

    private var stockVehicles: [Vehicle] {
        vehicles.filter { !$0.isSold }
    }

    private var filteredVehicles: [Vehicle] {

        guard !searchText.isEmpty else {
            return stockVehicles
        }

        let search = searchText.lowercased()

        return stockVehicles.filter {

            ($0.make ?? "").lowercased().contains(search) ||
            ($0.model ?? "").lowercased().contains(search) ||
            ($0.registrationNumber ?? "").lowercased().contains(search) ||
            ($0.vin ?? "").lowercased().contains(search) ||
            ($0.stockNumber ?? "").lowercased().contains(search)
        }
    }

    var body: some View {

        NavigationStack {

            List {

                ForEach(
                    filteredVehicles,
                    id: \.objectID
                ) { vehicle in

                    NavigationLink {

                        VehicleDetailView(
                            vehicle: vehicle
                        )

                    } label: {

                        VehicleRow(
                            vehicle: vehicle
                        )
                    }
                    .swipeActions(
                        edge: .trailing,
                        allowsFullSwipe: false
                    ) {

                        Button(
                            role: .destructive
                        ) {

                            vehicleToDelete = vehicle
                            showingDeleteAlert = true

                        } label: {

                            Label(
                                "Delete",
                                systemImage: "trash"
                            )
                        }
                    }
                }
            }
            .navigationTitle("Vehicles")
            .searchable(
                text: $searchText,
                prompt: "Reg, VIN, make or model"
            )
            .toolbar {

                ToolbarItem(
                    placement: .topBarLeading
                ) {
                    Button(action: exportStock) {
                        Label("Export Stock", systemImage: "square.and.arrow.up")
                    }
                    .disabled(stockVehicles.isEmpty)
                }

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button {

                        showingAddVehicle = true

                    } label: {

                        Image(
                            systemName: "plus"
                        )
                    }
                }
            }
            .sheet(
                isPresented: $showingAddVehicle
            ) {

                AddVehicleView()
            }
            .sheet(item: $exportFile) { file in
                SalesShareSheet(items: [file.url])
            }
            .alert("Could Not Export Stock", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "Unknown error")
            }
            .alert(
                "Delete Vehicle?",
                isPresented: $showingDeleteAlert
            ) {

                Button(
                    "Cancel",
                    role: .cancel
                ) {

                    vehicleToDelete = nil
                }

                Button(
                    "Delete",
                    role: .destructive
                ) {

                    deleteVehicle()
                }

            } message: {

                Text(
                    "This will permanently remove the vehicle and all of its recon items."
                )
            }
        }
    }

    private func deleteVehicle() {

        guard let vehicle = vehicleToDelete else {
            return
        }

        viewContext.delete(vehicle)

        do {

            try viewContext.save()

            vehicleToDelete = nil

        } catch {

            print(
                "Delete vehicle failed:",
                error.localizedDescription
            )
        }
    }

    private func exportStock() {
        do {
            exportFile = StockExportFile(
                url: try StockSpreadsheetExporter.export(stockVehicles)
            )
        } catch {
            exportError = error.localizedDescription
        }
    }
}

private struct StockExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

private struct VehicleRow: View {

    @ObservedObject var vehicle: Vehicle

    var body: some View {

        HStack {

            Image(systemName: "car.fill")
                .font(.title2)
                .frame(width: 45)

            VStack(alignment: .leading) {

                Text(vehicle.displayName)
                    .font(.headline)

                Text(
                    vehicle.registrationNumber
                    ?? "No registration"
                )
                .foregroundStyle(.secondary)

                Text(
                    vehicle.status
                    ?? "Purchased"
                )
                .font(.caption)
            }

            Spacer()

            VStack(alignment: .trailing) {

                Text(
                    Money.rand(
                        vehicle.totalCostCents
                    )
                )
                .font(.headline)

                Text("Total Cost")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
