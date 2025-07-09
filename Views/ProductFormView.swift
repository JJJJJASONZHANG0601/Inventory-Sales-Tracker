import SwiftUI

struct ProductFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var formData: ProductFormData
    let product: Product?
    let isEditing: Bool
    
    init(product: Product? = nil) {
        self.product = product
        self.isEditing = product != nil
        _formData = StateObject(wrappedValue: ProductFormData(product: product))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Product Information")) {
                TextField("Product Name", text: $formData.name)
                    .textInputAutocapitalization(.words)
                
                HStack {
                    Text("Quantity")
                    Spacer()
                    TextField("0", text: $formData.quantity)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Purchase Price")
                    Spacer()
                    TextField("0.00", text: $formData.purchasePrice)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Selling Price")
                    Spacer()
                    TextField("0.00", text: $formData.sellingPrice)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Low Stock Threshold")
                    Spacer()
                    TextField("10", text: $formData.lowStockThreshold)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            if isEditing {
                Section {
                    Button(role: .destructive) {
                        deleteProduct()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Product")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Product" : "Add Product")
        .navigationBarTitleDisplayMode(.inline)
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
                .disabled(!formData.isValid)
            }
        }
        .alert("Error", isPresented: $formData.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(formData.errorMessage)
        }
    }
    
    private func saveProduct() {
        withAnimation {
            let productToSave = product ?? Product(context: viewContext)
            
            productToSave.name = formData.name
            productToSave.quantity = Int32(formData.quantity) ?? 0
            productToSave.purchasePrice = Double(formData.purchasePrice) ?? 0.0
            productToSave.sellingPrice = Double(formData.sellingPrice) ?? 0.0
            productToSave.lowStockThreshold = Int32(formData.lowStockThreshold) ?? 10
            
            do {
                try viewContext.save()
                NotificationManager.shared.checkLowStockProducts(products: [productToSave])
                dismiss()
            } catch {
                formData.showError = true
                formData.errorMessage = "Failed to save product: \(error.localizedDescription)"
            }
        }
    }
    
    private func deleteProduct() {
        guard let product = product else { return }
        
        withAnimation {
            viewContext.delete(product)
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                formData.showError = true
                formData.errorMessage = "Failed to delete product: \(error.localizedDescription)"
            }
        }
    }
}

class ProductFormData: ObservableObject {
    @Published var name: String
    @Published var quantity: String
    @Published var purchasePrice: String
    @Published var sellingPrice: String
    @Published var lowStockThreshold: String
    
    @Published var showError = false
    @Published var errorMessage = ""
    
    init(product: Product?) {
        self.name = product?.name ?? ""
        self.quantity = product?.quantity.description ?? ""
        self.purchasePrice = String(format: "%.2f", product?.purchasePrice ?? 0.0)
        self.sellingPrice = String(format: "%.2f", product?.sellingPrice ?? 0.0)
        self.lowStockThreshold = product?.lowStockThreshold.description ?? "10"
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !quantity.isEmpty &&
        !purchasePrice.isEmpty &&
        !sellingPrice.isEmpty &&
        !lowStockThreshold.isEmpty
    }
}

#Preview {
    NavigationStack {
        ProductFormView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 