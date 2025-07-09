import SwiftUI
import CoreData

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("username") private var username = ""
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var role: String = UserDefaults.standard.string(forKey: "role") ?? ""
    
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Account")) {
                if isLoggedIn {
                    HStack {
                        Text("Logged in as")
                        Spacer()
                        Text(username)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Role")
                        Spacer()
                        Text(role)
                            .foregroundColor(.secondary)
                    }
                    
                    if role == "Manager" {
                        NavigationLink(destination: UserManagementView()) {
                            Label("User Management", systemImage: "person.3")
                        }
                    }
                    
                    Button(role: .destructive) {
                        isLoggedIn = false
                        username = ""
                        UserDefaults.standard.removeObject(forKey: "role")
                    } label: {
                        Text("Log Out")
                    }
                } else {
                    Text("Please log in from the main screen.")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $isDarkMode)
            }
            
            Section(header: Text("Notifications")) {
                if notificationManager.isAuthorized {
                    Text("Notifications are enabled")
                        .foregroundColor(.secondary)
                } else {
                    Button("Enable Notifications") {
                        notificationManager.requestAuthorization()
                    }
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
} 