import SwiftUI

struct SalesHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SaleRecord.date, ascending: false)],
        animation: .default)
    private var sales: FetchedResults<SaleRecord>
    
    @State private var searchText = ""
    @State private var selectedTimeFrame: TimeFrame = .all
    @State private var role: String = UserDefaults.standard.string(forKey: "role") ?? ""
    
    enum TimeFrame: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
        
        var date: Date? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .today:
                return calendar.startOfDay(for: now)
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: now)
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now)
            case .all:
                return nil
            }
        }
    }
    
    var filteredSales: [SaleRecord] {
        sales.filter { sale in
            let matchesSearch = searchText.isEmpty ||
                (sale.product?.name?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesTimeFrame = selectedTimeFrame.date == nil ||
                (sale.date ?? Date()) >= selectedTimeFrame.date!
            
            return matchesSearch && matchesTimeFrame
        }
    }
    
    var totalSales: Double {
        filteredSales.reduce(0) { $0 + $1.totalPrice }
    }
    
    var body: some View {
        if role == "Manager" || role == "Cashier" {
            List {
                Section {
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Text(timeFrame.rawValue).tag(timeFrame)
                        }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text("Total Sales")
                            .font(.headline)
                        Spacer()
                        Text("$\(String(format: "%.2f", totalSales))")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                Section {
                    ForEach(filteredSales) { sale in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(sale.product?.name ?? "Unknown Product")
                                    .font(.headline)
                                Spacer()
                                Text(sale.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Quantity: \(sale.quantity)")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("$\(String(format: "%.2f", sale.totalPrice))")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search by product name")
            .navigationTitle("Sales History")
            .onAppear { role = UserDefaults.standard.string(forKey: "role") ?? "" }
        } else {
            VStack {
                Spacer()
                Text("You do not have permission to view sales history.")
                    .foregroundColor(.secondary)
                    .font(.title3)
                Spacer()
            }
            .onAppear { role = UserDefaults.standard.string(forKey: "role") ?? "" }
        }
    }
}

#Preview {
    NavigationStack {
        SalesHistoryView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 