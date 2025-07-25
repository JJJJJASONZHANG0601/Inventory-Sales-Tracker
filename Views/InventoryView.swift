import SwiftUI
import UniformTypeIdentifiers

struct InventoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)],
        animation: .default)
    private var products: FetchedResults<Product>
    
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingAddProduct = false
    @State private var searchText = ""
    @State private var role: String = UserDefaults.standard.string(forKey: "role") ?? ""
    @State private var sortOption: SortOption = .nameAsc
    @State private var showExporter = false
    @State private var csvURL: URL? = nil
    
    enum SortOption: String, CaseIterable, Identifiable {
        case nameAsc = "Name ↑"
        case nameDesc = "Name ↓"
        case quantityAsc = "Quantity ↑"
        case quantityDesc = "Quantity ↓"
        case priceAsc = "Price ↑"
        case priceDesc = "Price ↓"
        var id: String { rawValue }
    }
    
    var sortedProducts: [Product] {
        let filtered = searchText.isEmpty ? Array(products) : products.filter { product in
            product.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }
        switch sortOption {
        case .nameAsc:
            return filtered.sorted { ($0.name ?? "") < ($1.name ?? "") }
        case .nameDesc:
            return filtered.sorted { ($0.name ?? "") > ($1.name ?? "") }
        case .quantityAsc:
            return filtered.sorted { $0.quantity < $1.quantity }
        case .quantityDesc:
            return filtered.sorted { $0.quantity > $1.quantity }
        case .priceAsc:
            return filtered.sorted { $0.sellingPrice < $1.sellingPrice }
        case .priceDesc:
            return filtered.sorted { $0.sellingPrice > $1.sellingPrice }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Picker("Sort by", selection: $sortOption) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                Spacer()
                Button(action: exportCSV) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
            .padding(.horizontal)
            List {
                ForEach(sortedProducts) { product in
                    NavigationLink(destination: ProductFormView(product: product).disabled(role != "Manager")) {
                        ProductRowView(product: product)
                    }
                }
                .onDelete(perform: role == "Manager" ? deleteProducts : nil)
            }
            .searchable(text: $searchText, prompt: "Search products")
        }
        .navigationTitle("Inventory")
        .toolbar {
            if role == "Manager" {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProduct = true }) {
                        Label("Add Product", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddProduct) {
            NavigationStack {
                ProductFormView()
            }
        }
        .onAppear {
            checkLowStock()
            role = UserDefaults.standard.string(forKey: "role") ?? ""
        }
        .onChange(of: products.count) { _ in
            checkLowStock()
        }
        .fileExporter(
            isPresented: $showExporter,
            document: csvURL.map { CSVDocument(url: $0) },
            contentType: .commaSeparatedText,
            defaultFilename: "Products.csv"
        ) { result in
            if case .success(_) = result {
                // 可选：导出成功提示
            }
        }
    }
    
    private func checkLowStock() {
        notificationManager.checkLowStockProducts(products: Array(products))
    }
    
    private func deleteProducts(offsets: IndexSet) {
        withAnimation {
            offsets.map { sortedProducts[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func exportCSV() {
        let header = "Name,Quantity,Purchase Price,Selling Price,Low Stock Threshold\n"
        let rows = sortedProducts.map { product in
            "\(product.name ?? "")" + "," + String(product.quantity) + "," + String(product.purchasePrice) + "," + String(product.sellingPrice) + "," + String(product.lowStockThreshold)
        }
        let csvString = header + rows.joined(separator: "\n")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Products.csv")
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            csvURL = tempURL
            showExporter = true
        } catch {
            // 错误处理
        }
    }
}

struct ProductRowView: View {
    @ObservedObject var product: Product
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name ?? "Unnamed Product")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Quantity: \(product.quantity)")
                        .foregroundColor(.secondary)
                    Text("Price: $\(String(format: "%.2f", product.sellingPrice))")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if product.quantity <= product.lowStockThreshold {
                    Label("Low Stock", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        InventoryView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 