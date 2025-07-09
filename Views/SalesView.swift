import SwiftUI

struct SalesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)],
        animation: .default)
    private var products: FetchedResults<Product>
    
    @State private var selectedProduct: Product?
    @State private var quantity: String = ""
    @State private var showingProductPicker = false
    @State private var showingConfirmation = false
    @State private var errorMessage: String?
    @State private var role: String = UserDefaults.standard.string(forKey: "role") ?? ""
    
    private var totalPrice: Double {
        guard let product = selectedProduct,
              let quantity = Int(quantity) else { return 0 }
        return product.sellingPrice * Double(quantity)
    }
    
    var body: some View {
        NavigationStack {
            if role == "Manager" || role == "Cashier" {
                Form {
                    Section(header: Text("Select Product")) {
                        Button(action: { showingProductPicker = true }) {
                            HStack {
                                Text(selectedProduct?.name ?? "Select a product")
                                    .foregroundColor(selectedProduct == nil ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    if selectedProduct != nil {
                        Section(header: Text("Sale Details")) {
                            HStack {
                                Text("Available Stock")
                                Spacer()
                                Text("\(selectedProduct?.quantity ?? 0)")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Unit Price")
                                Spacer()
                                Text("$\(String(format: "%.2f", selectedProduct?.sellingPrice ?? 0))")
                                    .foregroundColor(.secondary)
                            }
                            
                            TextField("Quantity", text: $quantity)
                                .keyboardType(.numberPad)
                        }
                        
                        Section(header: Text("Total")) {
                            HStack {
                                Text("Total Amount")
                                    .font(.headline)
                                Spacer()
                                Text("$\(String(format: "%.2f", totalPrice))")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Section {
                            Button(action: recordSale) {
                                HStack {
                                    Spacer()
                                    Text("Record Sale")
                                        .bold()
                                    Spacer()
                                }
                            }
                            .disabled(!isValidSale)
                        }
                    }
                }
                .navigationTitle("New Sale")
                .sheet(isPresented: $showingProductPicker) {
                    NavigationStack {
                        List(products) { product in
                            Button(action: {
                                selectedProduct = product
                                showingProductPicker = false
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(product.name ?? "")
                                            .foregroundColor(.primary)
                                        Text("Stock: \(product.quantity)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("$\(String(format: "%.2f", product.sellingPrice))")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .navigationTitle("Select Product")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showingProductPicker = false
                                }
                            }
                        }
                    }
                }
                .alert("Error", isPresented: .constant(errorMessage != nil)) {
                    Button("OK") {
                        errorMessage = nil
                    }
                } message: {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                    }
                }
                .alert("Sale Recorded", isPresented: $showingConfirmation) {
                    Button("OK") {
                        resetForm()
                    }
                } message: {
                    Text("The sale has been recorded successfully.")
                }
            } else {
                VStack {
                    Spacer()
                    Text("You do not have permission to record sales.")
                        .foregroundColor(.secondary)
                        .font(.title3)
                    Spacer()
                }
            }
        }
        .onAppear {
            role = UserDefaults.standard.string(forKey: "role") ?? ""
        }
    }
    
    private var isValidSale: Bool {
        guard let product = selectedProduct,
              let quantity = Int(quantity),
              quantity > 0 else { return false }
        return quantity <= product.quantity
    }
    
    private func recordSale() {
        guard let product = selectedProduct,
              let quantity = Int(quantity) else { return }
        
        withAnimation {
            // Create sale record
            let sale = SaleRecord(context: viewContext)
            sale.date = Date()
            sale.quantity = Int32(quantity)
            sale.totalPrice = totalPrice
            sale.product = product
            
            // Update product quantity
            product.quantity -= Int32(quantity)
            
            do {
                try viewContext.save()
                showingConfirmation = true
            } catch {
                errorMessage = "Failed to record sale: \(error.localizedDescription)"
            }
        }
    }
    
    private func resetForm() {
        selectedProduct = nil
        quantity = ""
    }
}

#Preview {
    SalesView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 