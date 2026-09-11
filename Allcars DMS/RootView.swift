import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }

            StockListView()
                .tabItem {
                    Label("Stock", systemImage: "car.fill")
                }

            SoldVehicleListView()
                .tabItem {
                    Label("Sold", systemImage: "checkmark.circle.fill")
                }

            DealershipSharingView()
                .tabItem {
                    Label("Dealership", systemImage: "building.2.fill")
                }
        }
        .task {
            do {
                _ = try PersistenceController.shared.dealership()
            } catch {
                print("Dealership setup failed:", error.localizedDescription)
            }
        }
    }
}
