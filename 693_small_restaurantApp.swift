import SwiftUI
import CoreData

@main
struct RestaurantInventoryApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            } else {
                WelcomeView(isLoggedIn: $isLoggedIn)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            }
        }
    }
}

// MARK: - Persistence Controller
struct PersistenceController {
    static let shared = PersistenceController()
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Add preview data here if needed
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "693_small_restaurant")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // 插入初始用户（仅首次启动且无用户时）
        insertInitialUsersIfNeeded(context: container.viewContext)
    }
    
    private func insertInitialUsersIfNeeded(context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        fetchRequest.fetchLimit = 1
        do {
            let count = try context.count(for: fetchRequest)
            if count == 0 {
                let manager = NSEntityDescription.insertNewObject(forEntityName: "User", into: context)
                manager.setValue("manager", forKey: "username")
                manager.setValue("manager123", forKey: "password")
                manager.setValue("Manager", forKey: "role")
                
                let staff = NSEntityDescription.insertNewObject(forEntityName: "User", into: context)
                staff.setValue("staff", forKey: "username")
                staff.setValue("staff123", forKey: "password")
                staff.setValue("Staff", forKey: "role")
                
                let cashier = NSEntityDescription.insertNewObject(forEntityName: "User", into: context)
                cashier.setValue("cashier", forKey: "username")
                cashier.setValue("cashier123", forKey: "password")
                cashier.setValue("Cashier", forKey: "role")
                
                try context.save()
            }
        } catch {
            print("Failed to insert initial users: \(error)")
        }
    }
} 