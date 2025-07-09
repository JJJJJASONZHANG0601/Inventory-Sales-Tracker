import SwiftUI
import Charts
import UniformTypeIdentifiers

struct ReportsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SaleRecord.date, ascending: true)],
        animation: .default)
    private var sales: FetchedResults<SaleRecord>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)],
        animation: .default)
    private var products: FetchedResults<Product>
    
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var selectedChart: ChartType = .sales
    @State private var role: String = UserDefaults.standard.string(forKey: "role") ?? ""
    @State private var showShareSheet = false
    @State private var csvURL: URL? = nil
    
    enum TimeFrame: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
        
        var date: Date {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: now)!
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now)!
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: now)!
            }
        }
    }
    
    enum ChartType: String, CaseIterable {
        case sales = "Sales Trend"
        case inventory = "Inventory Status"
    }
    
    var filteredSales: [SaleRecord] {
        sales.filter { sale in
            (sale.date ?? Date()) >= selectedTimeFrame.date
        }
    }
    
    var dailySales: [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        let groupedSales = Dictionary(grouping: filteredSales) { sale in
            calendar.startOfDay(for: sale.date ?? Date())
        }
        
        return groupedSales.map { (date, sales) in
            (date: date, amount: sales.reduce(0) { $0 + $1.totalPrice })
        }.sorted { $0.date < $1.date }
    }
    
    var totalSales: Double {
        filteredSales.reduce(0) { $0 + $1.totalPrice }
    }
    
    var averageDailySales: Double {
        guard !dailySales.isEmpty else { return 0 }
        return totalSales / Double(dailySales.count)
    }
    
    var body: some View {
        if role == "Manager" {
            NavigationStack {
                List {
                    Section {
                        Picker("Time Frame", selection: $selectedTimeFrame) {
                            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                                Text(timeFrame.rawValue).tag(timeFrame)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Picker("Chart Type", selection: $selectedChart) {
                            ForEach(ChartType.allCases, id: \.self) { chartType in
                                Text(chartType.rawValue).tag(chartType)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section {
                        if selectedChart == .sales {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sales Trend")
                                    .font(.headline)
                                
                                Chart {
                                    ForEach(dailySales, id: \.date) { sale in
                                        LineMark(
                                            x: .value("Date", sale.date),
                                            y: .value("Amount", sale.amount)
                                        )
                                        .foregroundStyle(.blue)
                                        
                                        PointMark(
                                            x: .value("Date", sale.date),
                                            y: .value("Amount", sale.amount)
                                        )
                                        .foregroundStyle(.blue)
                                    }
                                }
                                .frame(height: 200)
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day)) { value in
                                        AxisGridLine()
                                        AxisValueLabel(format: .dateTime.weekday())
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { value in
                                        AxisGridLine()
                                        AxisValueLabel("$\(value.as(Double.self)?.formatted() ?? "")")
                                    }
                                }
                            }
                            .padding(.vertical)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Total Sales")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("$\(String(format: "%.2f", totalSales))")
                                        .font(.headline)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Average Daily")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("$\(String(format: "%.2f", averageDailySales))")
                                        .font(.headline)
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Inventory Status")
                                    .font(.headline)
                                
                                Chart {
                                    ForEach(products) { product in
                                        BarMark(
                                            x: .value("Product", product.name ?? ""),
                                            y: .value("Quantity", product.quantity)
                                        )
                                        .foregroundStyle(product.quantity <= product.lowStockThreshold ? .red : .blue)
                                    }
                                }
                                .frame(height: 200)
                                .chartXAxis {
                                    AxisMarks { value in
                                        AxisValueLabel {
                                            if let name = value.as(String.self) {
                                                Text(name)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Total Products")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(products.count)")
                                        .font(.headline)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Low Stock Items")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(products.filter { $0.quantity <= $0.lowStockThreshold }.count)")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Reports")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: exportCSV) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                .sheet(isPresented: $showShareSheet, onDismiss: { csvURL = nil }) {
                    if let csvURL = csvURL {
                        ShareSheet(activityItems: [csvURL])
                    }
                }
                .onAppear { role = UserDefaults.standard.string(forKey: "role") ?? "" }
            }
        } else {
            VStack {
                Spacer()
                Text("You do not have permission to view reports.")
                    .foregroundColor(.secondary)
                    .font(.title3)
                Spacer()
            }
            .onAppear { role = UserDefaults.standard.string(forKey: "role") ?? "" }
        }
    }
    
    private func exportCSV() {
        let csvString = generateCSV()
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Report_Export.csv")
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            csvURL = fileURL
            showShareSheet = true
        } catch {
            // 可选：错误处理
        }
    }
    
    private func generateCSV() -> String {
        if selectedChart == .sales {
            var csv = "Date,Amount\n"
            for entry in dailySales {
                let dateStr = DateFormatter.localizedString(from: entry.date, dateStyle: .short, timeStyle: .none)
                csv += "\(dateStr),\(String(format: "%.2f", entry.amount))\n"
            }
            return csv
        } else {
            var csv = "Product,Quantity\n"
            for product in products {
                csv += "\(product.name ?? ""),\(product.quantity)\n"
            }
            return csv
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ReportsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 