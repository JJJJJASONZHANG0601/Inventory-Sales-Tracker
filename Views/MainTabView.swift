import SwiftUI

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var role: String = UserDefaults.standard.string(forKey: "role") ?? ""
    
    var body: some View {
        TabView {
            if role == "Manager" || role == "Staff" {
                NavigationStack {
                    InventoryView()
                }
                .tabItem {
                    Label("Inventory", systemImage: "list.bullet.clipboard")
                }
            }
            if role == "Manager" || role == "Cashier" {
                NavigationStack {
                    SalesView()
                }
                .tabItem {
                    Label("New Sale", systemImage: "cart")
                }
            }
            if role == "Manager" || role == "Cashier" {
                NavigationStack {
                    SalesHistoryView()
                }
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            }
            if role == "Manager" {
                NavigationStack {
                    SupplierListView()
                }
                .tabItem {
                    Label("Suppliers", systemImage: "person.2")
                }
            }
            if role == "Manager" {
                NavigationStack {
                    ReportsView()
                }
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }
            }
            if role == "Manager" {
                NavigationStack {
                    PurchaseOrderListView()
                }
                .tabItem {
                    Label("Purchase Orders", systemImage: "doc.plaintext")
                }
            }
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .onAppear {
            role = UserDefaults.standard.string(forKey: "role") ?? ""
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 