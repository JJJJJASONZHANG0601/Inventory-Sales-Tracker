import SwiftUI

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
    
    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return Array(products)
        }
        return products.filter { product in
            product.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredProducts) { product in
                NavigationLink(destination: ProductFormView(product: product).disabled(role != "Manager")) {
                    ProductRowView(product: product)
                }
            }
            .onDelete(perform: role == "Manager" ? deleteProducts : nil)
        }
        .searchable(text: $searchText, prompt: "Search products")
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
    }
    
    private func checkLowStock() {
        notificationManager.checkLowStockProducts(products: Array(products))
    }
    
    private func deleteProducts(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredProducts[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
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