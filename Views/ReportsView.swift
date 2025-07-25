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
    @State private var showExporter = false
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
                                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                                        AxisGridLine()
                                        AxisValueLabel() {
                                            if let date = value.as(Date.self) {
                                                Text(date, format: .dateTime.month().day())
                                                    .font(.caption2)
                                                    .rotationEffect(.degrees(-45))
                                                    .lineLimit(1)
                                            }
                                        }
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
                .fileExporter(
                    isPresented: $showExporter,
                    document: csvURL.map { CSVDocument(url: $0) },
                    contentType: .commaSeparatedText,
                    defaultFilename: selectedChart == .sales ? "SalesDetails.csv" : "InventoryDetails.csv"
                ) { result in
                    if case .success(_) = result {
                        // 可选：导出成功提示
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
        let csvString: String
        if selectedChart == .sales {
            csvString = generateSalesDetailsCSV()
        } else {
            csvString = generateInventoryDetailsCSV()
        }
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(selectedChart == .sales ? "SalesDetails.csv" : "InventoryDetails.csv")
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            csvURL = fileURL
            showExporter = true
        } catch {
            // 可选：错误处理
        }
    }
    
    private func generateSalesDetailsCSV() -> String {
        var csv = "Date,Product,Quantity,Total Price\n"
        for sale in filteredSales {
            let dateStr = DateFormatter.localizedString(from: sale.date ?? Date(), dateStyle: .short, timeStyle: .none)
            let product = sale.product?.name ?? ""
            let quantity = sale.quantity
            let total = String(format: "%.2f", sale.totalPrice)
            csv += "\(dateStr),\(product),\(quantity),\(total)\n"
        }
        return csv
    }
    
    private func generateInventoryDetailsCSV() -> String {
        var csv = "Product,Quantity,Purchase Price,Selling Price,Low Stock Threshold\n"
        for product in products {
            csv += "\(product.name ?? ""),\(product.quantity),\(product.purchasePrice),\(product.sellingPrice),\(product.lowStockThreshold)\n"
        }
        return csv
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