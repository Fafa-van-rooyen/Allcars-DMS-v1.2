import SwiftUI
import CoreData

struct SoldVehicleListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.saleDate, ascending: false)],
        animation: .default
    ) private var vehicles: FetchedResults<Vehicle>

    @State private var searchText = ""
    @State private var exportFile: SalesExportFile?
    @State private var exportError: String?

    private var soldVehicles: [Vehicle] {
        let sold = vehicles.filter(\.isSold)
        guard !searchText.isEmpty else { return sold }
        let search = searchText.lowercased()
        return sold.filter {
            ($0.make ?? "").lowercased().contains(search) ||
            ($0.model ?? "").lowercased().contains(search) ||
            ($0.registrationNumber ?? "").lowercased().contains(search) ||
            ($0.buyerFirstNames ?? "").lowercased().contains(search) ||
            ($0.buyerSurname ?? "").lowercased().contains(search)
        }
    }

    private var monthlyGroups: [SalesMonthGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: soldVehicles) { vehicle in
            let date = vehicle.saleDate ?? .distantPast
            return SalesMonthKey(
                year: calendar.component(.year, from: date),
                month: calendar.component(.month, from: date)
            )
        }
        return grouped.map { key, vehicles in
            SalesMonthGroup(key: key, vehicles: vehicles)
        }.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            salesList
            .overlay {
                if soldVehicles.isEmpty && searchText.isEmpty {
                    ContentUnavailableView(
                        "No Sold Vehicles",
                        systemImage: "checkmark.circle",
                        description: Text("Completed sales will appear here by month.")
                    )
                }
            }
            .navigationTitle("Sold Vehicles")
            .searchable(text: $searchText, prompt: "Vehicle or buyer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: exportSales) {
                        Label("Export Sales", systemImage: "square.and.arrow.up")
                    }
                    .disabled(soldVehicles.isEmpty)
                }
            }
            .sheet(item: $exportFile) { file in
                SalesShareSheet(items: [file.url])
            }
            .alert("Could Not Export Sales", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "Unknown error")
            }
        }
    }

    private var salesList: some View {
        List {
            ForEach(monthlyGroups) { group in
                Section(group.title) {
                    ForEach(group.vehicles, id: \.objectID) { vehicle in
                        NavigationLink {
                            VehicleDetailView(vehicle: vehicle)
                        } label: {
                            soldRow(vehicle)
                        }
                    }
                }
            }
        }
    }

    private func soldRow(_ vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(vehicle.displayName).font(.headline)
            HStack {
                Text(vehicle.registrationNumber ?? "No registration")
                Spacer()
                Text(Money.rand(vehicle.salePriceCents)).fontWeight(.semibold)
            }
            .foregroundStyle(.secondary)
            if vehicle.hasOutstandingRecon {
                Label(
                    "Recon still owing: \(Money.rand(vehicle.outstandingReconCents))",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private func exportSales() {
        do {
            exportFile = SalesExportFile(url: try SalesSpreadsheetExporter.export(soldVehicles))
        } catch {
            exportError = error.localizedDescription
        }
    }
}

private struct SalesMonthKey: Hashable, Comparable {
    let year: Int
    let month: Int
    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}

private struct SalesMonthGroup: Identifiable {
    let key: SalesMonthKey
    let vehicles: [Vehicle]
    var id: String { "\(key.year)-\(key.month)" }
    var title: String {
        let components = DateComponents(year: key.year, month: key.month)
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(.dateTime.month(.wide).year())
    }
}

private struct SalesExportFile: Identifiable {
    let id = UUID()
    let url: URL
}
