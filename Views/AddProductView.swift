import SwiftUI

struct AddProductView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var quantity = ""
    @State private var purchasePrice = ""
    @State private var sellingPrice = ""
    @State private var lowStockThreshold = ""
    
    var body: some View {
        Form {
            Section(header: Text("Product Information")) {
                TextField("Product Name", text: $name)
                TextField("Quantity", text: $quantity)
                TextField("Purchase Price", text: $purchasePrice)
                TextField("Selling Price", text: $sellingPrice)
                TextField("Low Stock Threshold", text: $lowStockThreshold)
            }
        }
        .navigationTitle("Add Product")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveProduct()
                }
                .disabled(name.isEmpty)
            }
        }
    }
    
    private func saveProduct() {
        withAnimation {
            let newProduct = Product(context: viewContext)
            newProduct.name = name
            newProduct.quantity = Int32(quantity) ?? 0
            newProduct.purchasePrice = Double(purchasePrice) ?? 0.0
            newProduct.sellingPrice = Double(sellingPrice) ?? 0.0
            newProduct.lowStockThreshold = Int32(lowStockThreshold) ?? 10
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddProductView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 