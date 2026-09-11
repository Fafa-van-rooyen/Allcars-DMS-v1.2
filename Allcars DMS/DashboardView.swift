import SwiftUI
import CoreData

struct DashboardView: View {

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

    // MARK: - Current Stock

    private var currentStock: [Vehicle] {

        vehicles.filter {
            !$0.isSold
        }
    }

    // MARK: - Sold Vehicles

    private var soldVehicles: [Vehicle] {

        vehicles.filter {
            $0.isSold
        }
    }

    // MARK: - Outstanding Recon

    private var outstandingReconVehicles: [Vehicle] {

        vehicles.filter {
            $0.hasOutstandingRecon
        }
    }

    // MARK: - Dashboard Totals

    private var stockInvestment: Int64 {

        vehicles.reduce(
            into: Int64(0)
        ) { total, vehicle in

            total += vehicle.totalCostCents
        }
    }

    private var outstandingReconTotal: Int64 {

        currentStock.reduce(
            into: Int64(0)
        ) { total, vehicle in

            total += vehicle.outstandingReconCents
        }
    }

    private var totalProfit: Int64 {

        soldVehicles.reduce(
            into: Int64(0)
        ) { total, vehicle in

            total += vehicle.actualProfitCents
        }
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 16) {

                    // Vehicles in Stock

                    NavigationLink {

                        DashboardVehicleListView(
                            title: "Vehicles in Stock",
                            vehicles: currentStock,
                            mode: .stock
                        )

                    } label: {

                        dashboardCard(
                            title: "Vehicles in Stock",
                            value: "\(currentStock.count)",
                            icon: "car.2.fill"
                        )
                    }
                    .buttonStyle(.plain)

                    // Money in Stock

                    NavigationLink {

                        DashboardVehicleListView(
                            title: "Money in Stock",
                            vehicles: currentStock,
                            mode: .stock
                        )

                    } label: {

                        dashboardCard(
                            title: "Money in Stock",
                            value:
                                Money.rand(
                                    stockInvestment
                                ),
                            icon: "banknote.fill"
                        )
                    }
                    .buttonStyle(.plain)

                    // Outstanding Recon

                    NavigationLink {

                        DashboardVehicleListView(
                            title: "Outstanding Recon",
                            vehicles:
                                outstandingReconVehicles,
                            mode: .recon
                        )

                    } label: {

                        dashboardCard(
                            title: "Outstanding Recon",
                            value:
                                Money.rand(
                                    outstandingReconTotal
                                ),
                            icon:
                                "wrench.and.screwdriver.fill"
                        )
                    }
                    .buttonStyle(.plain)

                    // Sold Vehicles

                    NavigationLink {

                        DashboardVehicleListView(
                            title: "Sold Vehicles",
                            vehicles: soldVehicles,
                            mode: .sold
                        )

                    } label: {

                        dashboardCard(
                            title: "Sold Vehicles",
                            value:
                                "\(soldVehicles.count)",
                            icon:
                                "checkmark.circle.fill"
                        )
                    }
                    .buttonStyle(.plain)

                    // Gross Profit

                    NavigationLink {

                        DashboardVehicleListView(
                            title: "Gross Profit",
                            vehicles: soldVehicles,
                            mode: .sold
                        )

                    } label: {

                        dashboardCard(
                            title: "Gross Profit",
                            value:
                                Money.rand(
                                    totalProfit
                                ),
                            icon:
                                "chart.line.uptrend.xyaxis"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("All Cars DMS")
        }
    }

    // MARK: - Dashboard Card

    private func dashboardCard(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        HStack(spacing: 18) {

            Image(systemName: icon)
                .font(
                    .system(
                        size: 28
                    )
                )
                .frame(width: 45)

            VStack(
                alignment: .leading
            ) {

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )

                Text(value)
                    .font(
                        .title2.bold()
                    )
                    .foregroundStyle(
                        .primary
                    )
            }

            Spacer()

            Image(
                systemName:
                    "chevron.right"
            )
            .foregroundStyle(
                .secondary
            )
        }
        .padding()
        .background(
            .regularMaterial,
            in:
                RoundedRectangle(
                    cornerRadius: 18
                )
        )
    }
}
