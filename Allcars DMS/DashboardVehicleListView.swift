import SwiftUI

enum DashboardVehicleListMode {

    case stock
    case recon
    case sold
}

struct DashboardVehicleListView: View {

    let title: String
    let vehicles: [Vehicle]
    let mode: DashboardVehicleListMode

    var body: some View {

        List {

            if vehicles.isEmpty {

                ContentUnavailableView(
                    "No Vehicles",
                    systemImage: "car",
                    description:
                        Text(
                            emptyMessage
                        )
                )

            } else {

                ForEach(
                    vehicles,
                    id: \.objectID
                ) { vehicle in

                    NavigationLink {

                        VehicleDetailView(
                            vehicle: vehicle
                        )

                    } label: {

                        vehicleRow(
                            vehicle
                        )
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(
            .inline
        )
    }

    // MARK: - Vehicle Row

    private func vehicleRow(
        _ vehicle: Vehicle
    ) -> some View {

        HStack {

            Image(
                systemName:
                    iconForMode
            )
            .font(.title2)
            .frame(width: 45)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    vehicle.displayName
                )
                .font(.headline)

                Text(
                    vehicle.registrationNumber
                    ?? "No registration"
                )
                .foregroundStyle(
                    .secondary
                )

                if mode == .recon {

                    Text(
                        "Outstanding Recon"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .orange
                    )
                }

                if mode == .sold {

                    Text("Sold")
                        .font(.caption)
                        .foregroundStyle(
                            .green
                        )
                }
            }

            Spacer()

            VStack(
                alignment: .trailing,
                spacing: 4
            ) {

                switch mode {

                case .stock:

                    Text(
                        Money.rand(
                            vehicle.totalCostCents
                        )
                    )
                    .font(.headline)

                    Text("Total Cost")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                case .recon:

                    Text(
                        Money.rand(
                            vehicle.outstandingReconCents
                        )
                    )
                    .font(.headline)
                    .foregroundStyle(
                        .orange
                    )

                    Text("Outstanding")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                case .sold:

                    Text(
                        Money.rand(
                            vehicle.salePriceCents
                        )
                    )
                    .font(.headline)

                    Text(
                        "Profit \(Money.rand(vehicle.actualProfitCents))"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        vehicle.actualProfitCents >= 0
                        ? .green
                        : .red
                    )
                }
            }
        }
        .padding(
            .vertical,
            4
        )
    }

    private var iconForMode: String {

        switch mode {

        case .stock:
            return "car.fill"

        case .recon:
            return
                "wrench.and.screwdriver.fill"

        case .sold:
            return
                "checkmark.circle.fill"
        }
    }

    private var emptyMessage: String {

        switch mode {

        case .stock:
            return
                "There are no vehicles in stock."

        case .recon:
            return
                "There are no outstanding recon invoices."

        case .sold:
            return
                "There are no sold vehicles yet."
        }
    }
}
