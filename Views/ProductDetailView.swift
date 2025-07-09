import SwiftUI

struct ProductDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var product: Product
    
    @State private var isEditing = false
    @State private var editedName: String
    @State private var editedQuantity: String
    @State private var editedPurchasePrice: String
    @State private var editedSellingPrice: String
    @State private var editedLowStockThreshold: String
    
    init(product: Product) {
        self.product = product
        _editedName = State(initialValue: product.name ?? "")
        _editedQuantity = State(initialValue: String(product.quantity))
        _editedPurchasePrice = State(initialValue: String(product.purchasePrice))
        _editedSellingPrice = State(initialValue: String(product.sellingPrice))
        _editedLowStockThreshold = State(initialValue: String(product.lowStockThreshold))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Product Details")) {
                if isEditing {
                    TextField("Name", text: $editedName)
                    TextField("Quantity", text: $editedQuantity)
                    TextField("Purchase Price", text: $editedPurchasePrice)
                    TextField("Selling Price", text: $editedSellingPrice)
                    TextField("Low Stock Threshold", text: $editedLowStockThreshold)
                } else {
                    LabeledContent("Name", value: product.name ?? "")
                    LabeledContent("Quantity", value: String(product.quantity))
                    LabeledContent("Purchase Price", value: String(format: "%.2f", product.purchasePrice))
                    LabeledContent("Selling Price", value: String(format: "%.2f", product.sellingPrice))
                    LabeledContent("Low Stock Threshold", value: String(product.lowStockThreshold))
                }
            }
            
            if !isEditing {
                Section(header: Text("Sales History")) {
                    if let sales = product.sales?.allObjects as? [SaleRecord], !sales.isEmpty {
                        ForEach(sales) { sale in
                            VStack(alignment: .leading) {
                                Text(sale.date?.formatted() ?? "")
                                    .font(.caption)
                                Text("Quantity: \(sale.quantity)")
                                Text("Total: $\(String(format: "%.2f", sale.totalPrice))")
                            }
                        }
                    } else {
                        Text("No sales recorded")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Product" : "Product Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            }
        }
    }
    
    private func saveChanges() {
        withAnimation {
            product.name = editedName
            product.quantity = Int32(editedQuantity) ?? product.quantity
            product.purchasePrice = Double(editedPurchasePrice) ?? product.purchasePrice
            product.sellingPrice = Double(editedSellingPrice) ?? product.sellingPrice
            product.lowStockThreshold = Int32(editedLowStockThreshold) ?? product.lowStockThreshold
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: Product())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 