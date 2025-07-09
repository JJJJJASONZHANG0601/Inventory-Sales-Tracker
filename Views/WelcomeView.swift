import SwiftUI
import CoreData

struct WelcomeView: View {
    @Binding var isLoggedIn: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loginError: String? = nil
    @State private var isLoading = false
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showError: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo and Title
                VStack(spacing: 20) {
                    Image(systemName: "fork.knife.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    
                    Text("Restaurant Inventory")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Manage your inventory and sales with ease")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // 登录表单
                VStack(spacing: 15) {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    if showError, let loginError = loginError {
                        Text(loginError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .transition(.opacity)
                            .padding(.bottom, 4)
                    }
                    
                    Button(action: {
                        login()
                    }) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Log In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background((username.isEmpty || password.isEmpty) ? Color.gray : Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(username.isEmpty || password.isEmpty || isLoading)
                    
                    if username.isEmpty || password.isEmpty {
                        Text("Please enter both username and password.")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func login() {
        isLoading = true
        loginError = nil
        showError = false
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "username == %@ AND password == %@", username, password)
        fetchRequest.fetchLimit = 1
        do {
            if let result = try viewContext.fetch(fetchRequest).first as? NSManagedObject,
               let role = result.value(forKey: "role") as? String {
                UserDefaults.standard.set(username, forKey: "username")
                UserDefaults.standard.set(role, forKey: "role")
                isLoggedIn = true
            } else {
                loginError = "Invalid username or password."
                showError = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showError = false
                }
            }
        } catch {
            loginError = "Login failed: \(error.localizedDescription)"
            showError = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showError = false
            }
        }
        isLoading = false
    }
}

#Preview {
    WelcomeView(isLoggedIn: .constant(false))
} 