import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct UserManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \User.username, ascending: true)]
    ) private var users: FetchedResults<User>
    
    @State private var showingAddUser = false
    @State private var editingUser: User? = nil
    @State private var showEditSheet = false
    @State private var errorMessage: String? = nil
    @State private var showDeleteAlert = false
    @State private var userToDelete: User? = nil
    
    var body: some View {
        NavigationView {
            List {
                ForEach(users) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.username ?? "")
                                .font(.headline)
                            Text(user.role ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            editingUser = user
                            showEditSheet = true
                        }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        Button(role: .destructive, action: {
                            userToDelete = user
                            showDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
            .navigationTitle("User Management")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddUser = true }) {
                        Label("Add User", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddUser) {
                AddOrEditUserView(isPresented: $showingAddUser, userToEdit: nil, existingUsers: users.map { $0 })
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showEditSheet) {
                if let editingUser = editingUser {
                    AddOrEditUserView(isPresented: $showEditSheet, userToEdit: editingUser, existingUsers: users.map { $0 })
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Delete User", isPresented: $showDeleteAlert, presenting: userToDelete) { user in
                Button("Delete", role: .destructive) { deleteUser(user) }
                Button("Cancel", role: .cancel) { userToDelete = nil }
            } message: { user in
                Text("Are you sure you want to delete user \(user.username ?? "")?")
            }
        }
    }
    
    private func deleteUser(_ user: User) {
        withAnimation {
            viewContext.delete(user)
            do {
                try viewContext.save()
            } catch {
                errorMessage = "Failed to delete user: \(error.localizedDescription)"
            }
        }
    }
}

struct AddOrEditUserView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    var userToEdit: User?
    var existingUsers: [User]
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var role: String = "Staff"
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    
    let roles = ["Manager", "Staff", "Cashier"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(userToEdit == nil ? "Add User" : "Edit User")) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                    Picker("Role", selection: $role) {
                        ForEach(roles, id: \.self) { r in
                            Text(r)
                        }
                    }
                }
                if showError, let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .transition(.opacity)
                        .padding(.bottom, 4)
                }
            }
            .navigationTitle(userToEdit == nil ? "Add User" : "Edit User")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveUser() }
                        .disabled(username.isEmpty || password.isEmpty)
                }
            }
            .onAppear {
                if let user = userToEdit {
                    username = user.username ?? ""
                    password = user.password ?? ""
                    role = user.role ?? "Staff"
                }
            }
        }
    }
    
    private func saveUser() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedUsername.isEmpty {
            errorMessage = "Username cannot be empty."
            showError = true
            autoHideError()
            return
        }
        if password.isEmpty {
            errorMessage = "Password cannot be empty."
            showError = true
            autoHideError()
            return
        }
        let isDuplicate = existingUsers.contains { $0.username == trimmedUsername && $0 != userToEdit }
        if isDuplicate {
            errorMessage = "Username already exists."
            showError = true
            autoHideError()
            return
        }
        withAnimation {
            let user: User
            if let userToEdit = userToEdit {
                user = userToEdit
            } else {
                user = User(context: viewContext)
            }
            user.username = trimmedUsername
            user.password = password
            user.role = role
            do {
                try viewContext.save()
                isPresented = false
            } catch {
                errorMessage = "Failed to save user: \(error.localizedDescription)"
                showError = true
                autoHideError()
            }
        }
    }
    
    private func autoHideError() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }
} 

struct SupplierListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Supplier.name, ascending: true)],
        animation: .default)
    private var suppliers: FetchedResults<Supplier>
    
    @State private var showingAddSupplier = false
    @State private var selectedSupplier: Supplier?
    @State private var searchText = ""
    @State private var sortOption: SortOption = .nameAsc
    @State private var showExporter = false
    @State private var csvURL: URL? = nil
    
    enum SortOption: String, CaseIterable, Identifiable {
        case nameAsc = "Name ↑"
        case nameDesc = "Name ↓"
        case contactAsc = "Contact ↑"
        case contactDesc = "Contact ↓"
        var id: String { rawValue }
    }
    
    var sortedSuppliers: [Supplier] {
        let filtered = searchText.isEmpty ? Array(suppliers) : suppliers.filter { supplier in
            (supplier.name ?? "").localizedCaseInsensitiveContains(searchText)
        }
        switch sortOption {
        case .nameAsc:
            return filtered.sorted { ($0.name ?? "") < ($1.name ?? "") }
        case .nameDesc:
            return filtered.sorted { ($0.name ?? "") > ($1.name ?? "") }
        case .contactAsc:
            return filtered.sorted { ($0.contactInfo ?? "") < ($1.contactInfo ?? "") }
        case .contactDesc:
            return filtered.sorted { ($0.contactInfo ?? "") > ($1.contactInfo ?? "") }
        }
    }
    
    var body: some View {
        NavigationStack {
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
                    ForEach(sortedSuppliers) { supplier in
                        NavigationLink(destination: SupplierDetailView(supplier: supplier)) {
                            VStack(alignment: .leading) {
                                Text(supplier.name ?? "Unnamed Supplier")
                                    .font(.headline)
                                if let contact = supplier.contactInfo, !contact.isEmpty {
                                    Text(contact)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteSuppliers)
                }
                .searchable(text: $searchText, prompt: "Search suppliers")
            }
            .navigationTitle("Suppliers")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSupplier = true }) {
                        Label("Add Supplier", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSupplier) {
                NavigationStack {
                    SupplierFormView()
                }
            }
            .fileExporter(
                isPresented: $showExporter,
                document: csvURL.map { CSVDocument(url: $0) },
                contentType: .commaSeparatedText,
                defaultFilename: "Suppliers.csv"
            ) { result in
                if case .success(_) = result {
                    // 可选：导出成功提示
                }
            }
        }
    }
    
    private func deleteSuppliers(offsets: IndexSet) {
        withAnimation {
            offsets.map { sortedSuppliers[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                // 错误处理
            }
        }
    }
    
    private func exportCSV() {
        let header = "Name,Contact Info,Address,Notes\n"
        let rows = sortedSuppliers.map { supplier in
            [
                supplier.name ?? "",
                supplier.contactInfo ?? "",
                supplier.address ?? "",
                supplier.notes ?? ""
            ].joined(separator: ",")
        }
        let csvString = header + rows.joined(separator: "\n")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Suppliers.csv")
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            csvURL = tempURL
            showExporter = true
        } catch {
            // 错误处理
        }
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var url: URL
    init(url: URL) { self.url = url }
    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadCorruptFile)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: url, options: .withoutMapping)
    }
}

struct SupplierFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var contactInfo: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""
    
    var supplier: Supplier?
    var isEditing: Bool { supplier != nil }
    
    init(supplier: Supplier? = nil) {
        self.supplier = supplier
        if let supplier = supplier {
            _name = State(initialValue: supplier.name ?? "")
            _contactInfo = State(initialValue: supplier.contactInfo ?? "")
            _address = State(initialValue: supplier.address ?? "")
            _notes = State(initialValue: supplier.notes ?? "")
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Supplier Information")) {
                TextField("Name", text: $name)
                TextField("Contact Info", text: $contactInfo)
                TextField("Address", text: $address)
                TextField("Notes", text: $notes)
            }
        }
        .navigationTitle(isEditing ? "Edit Supplier" : "Add Supplier")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveSupplier() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private func saveSupplier() {
        withAnimation {
            let supplierToSave = supplier ?? Supplier(context: viewContext)
            supplierToSave.name = name
            supplierToSave.contactInfo = contactInfo
            supplierToSave.address = address
            supplierToSave.notes = notes
            do {
                try viewContext.save()
                dismiss()
            } catch {
                // 错误处理
            }
        }
    }
}

struct SupplierDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var supplier: Supplier
    
    var purchaseOrders: [PurchaseOrder] {
        let set = supplier.purchaseOrders as? Set<PurchaseOrder> ?? []
        return set.sorted { ($0.purchaseDate ?? Date.distantPast) > ($1.purchaseDate ?? Date.distantPast) }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Supplier Details")) {
                LabeledContent("Name", value: supplier.name ?? "")
                if let contact = supplier.contactInfo, !contact.isEmpty {
                    LabeledContent("Contact Info", value: contact)
                }
                if let address = supplier.address, !address.isEmpty {
                    LabeledContent("Address", value: address)
                }
                if let notes = supplier.notes, !notes.isEmpty {
                    LabeledContent("Notes", value: notes)
                }
            }
            Section(header: Text("Purchase History")) {
                if purchaseOrders.isEmpty {
                    Text("No purchase records.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(purchaseOrders) { order in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(order.product?.name ?? "Unknown Product")
                                .font(.headline)
                            HStack {
                                Text("Date: ")
                                Text(order.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "-")
                            }
                            HStack {
                                Text("Quantity: \(order.quantity)")
                                Spacer()
                                Text("Price: $\(String(format: "%.2f", order.purchasePrice))")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Supplier Details")
    }
}

struct PurchaseOrderListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PurchaseOrder.purchaseDate, ascending: false)],
        animation: .default)
    private var purchaseOrders: FetchedResults<PurchaseOrder>
    
    @State private var showingAddOrder = false
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateDesc
    @State private var showExporter = false
    @State private var csvURL: URL? = nil
    
    enum SortOption: String, CaseIterable, Identifiable {
        case dateDesc = "Date ↓"
        case dateAsc = "Date ↑"
        case productAsc = "Product ↑"
        case productDesc = "Product ↓"
        case supplierAsc = "Supplier ↑"
        case supplierDesc = "Supplier ↓"
        var id: String { rawValue }
    }
    
    var sortedOrders: [PurchaseOrder] {
        let filtered = searchText.isEmpty ? Array(purchaseOrders) : purchaseOrders.filter { order in
            (order.product?.name ?? "").localizedCaseInsensitiveContains(searchText) ||
            (order.supplier?.name ?? "").localizedCaseInsensitiveContains(searchText)
        }
        switch sortOption {
        case .dateDesc:
            return filtered.sorted { ($0.purchaseDate ?? Date.distantPast) > ($1.purchaseDate ?? Date.distantPast) }
        case .dateAsc:
            return filtered.sorted { ($0.purchaseDate ?? Date.distantPast) < ($1.purchaseDate ?? Date.distantPast) }
        case .productAsc:
            return filtered.sorted { ($0.product?.name ?? "") < ($1.product?.name ?? "") }
        case .productDesc:
            return filtered.sorted { ($0.product?.name ?? "") > ($1.product?.name ?? "") }
        case .supplierAsc:
            return filtered.sorted { ($0.supplier?.name ?? "") < ($1.supplier?.name ?? "") }
        case .supplierDesc:
            return filtered.sorted { ($0.supplier?.name ?? "") > ($1.supplier?.name ?? "") }
        }
    }
    
    var body: some View {
        NavigationStack {
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
                    ForEach(sortedOrders) { order in
                        NavigationLink(destination: PurchaseOrderFormView(order: order)) {
                            VStack(alignment: .leading) {
                                Text(order.product?.name ?? "Unknown Product")
                                    .font(.headline)
                                Text("Supplier: \(order.supplier?.name ?? "-")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Text("Date: \(order.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "-")")
                                    Spacer()
                                    Text("Qty: \(order.quantity)")
                                    Spacer()
                                    Text("Price: $\(String(format: "%.2f", order.purchasePrice))")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteOrders)
                }
                .searchable(text: $searchText, prompt: "Search by product or supplier")
            }
            .navigationTitle("Purchase Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddOrder = true }) {
                        Label("Add Order", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddOrder) {
                NavigationStack {
                    PurchaseOrderFormView()
                }
            }
            .fileExporter(
                isPresented: $showExporter,
                document: csvURL.map { CSVDocument(url: $0) },
                contentType: .commaSeparatedText,
                defaultFilename: "PurchaseOrders.csv"
            ) { result in
                if case .success(_) = result {
                    // 可选：导出成功提示
                }
            }
        }
    }
    
    private func deleteOrders(offsets: IndexSet) {
        withAnimation {
            offsets.map { sortedOrders[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                // 错误处理
            }
        }
    }
    
    private func exportCSV() {
        let header = "Product,Supplier,Quantity,Purchase Price,Purchase Date\n"
        let rows = sortedOrders.map { order in
            [
                order.product?.name ?? "",
                order.supplier?.name ?? "",
                String(order.quantity),
                String(order.purchasePrice),
                order.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
            ].joined(separator: ",")
        }
        let csvString = header + rows.joined(separator: "\n")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("PurchaseOrders.csv")
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            csvURL = tempURL
            showExporter = true
        } catch {
            // 错误处理
        }
    }
}

struct PurchaseOrderFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Product.name, ascending: true)]
    ) private var products: FetchedResults<Product>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Supplier.name, ascending: true)]
    ) private var suppliers: FetchedResults<Supplier>
    
    @State private var selectedProduct: Product?
    @State private var selectedSupplier: Supplier?
    @State private var quantity: String = ""
    @State private var purchasePrice: String = ""
    @State private var purchaseDate: Date = Date()
    
    var order: PurchaseOrder?
    var isEditing: Bool { order != nil }
    
    init(order: PurchaseOrder? = nil) {
        self.order = order
        if let order = order {
            _selectedProduct = State(initialValue: order.product)
            _selectedSupplier = State(initialValue: order.supplier)
            _quantity = State(initialValue: String(order.quantity))
            _purchasePrice = State(initialValue: String(order.purchasePrice))
            _purchaseDate = State(initialValue: order.purchaseDate ?? Date())
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Product & Supplier")) {
                Picker("Product", selection: $selectedProduct) {
                    Text("Select Product").tag(Product?.none)
                    ForEach(products) { product in
                        Text(product.name ?? "Unnamed").tag(Product?.some(product))
                    }
                }
                Picker("Supplier", selection: $selectedSupplier) {
                    Text("Select Supplier").tag(Supplier?.none)
                    ForEach(suppliers) { supplier in
                        Text(supplier.name ?? "Unnamed").tag(Supplier?.some(supplier))
                    }
                }
            }
            Section(header: Text("Order Details")) {
                TextField("Quantity", text: $quantity)
                    .keyboardType(.numberPad)
                TextField("Purchase Price", text: $purchasePrice)
                    .keyboardType(.decimalPad)
                DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
            }
        }
        .navigationTitle(isEditing ? "Edit Order" : "Add Order")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveOrder() }
                    .disabled(!isValid)
            }
        }
    }
    
    private var isValid: Bool {
        selectedProduct != nil && selectedSupplier != nil &&
        Int32(quantity) != nil && Double(purchasePrice) != nil
    }
    
    private func saveOrder() {
        withAnimation {
            let orderToSave = order ?? PurchaseOrder(context: viewContext)
            orderToSave.product = selectedProduct
            orderToSave.supplier = selectedSupplier
            orderToSave.quantity = Int32(quantity) ?? 0
            orderToSave.purchasePrice = Double(purchasePrice) ?? 0.0
            orderToSave.purchaseDate = purchaseDate
            do {
                try viewContext.save()
                dismiss()
            } catch {
                // 错误处理
            }
        }
    }
}

// 预览
#Preview {
    let context = PersistenceController.preview.container.viewContext
    let supplier = Supplier(context: context)
    supplier.name = "测试供应商"
    return SupplierDetailView(supplier: supplier)
        .environment(\.managedObjectContext, context)
} 