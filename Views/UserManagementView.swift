import SwiftUI
import CoreData

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