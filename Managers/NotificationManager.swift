import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    print("Error requesting notification authorization: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleLowStockNotification(for product: Product) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Low Stock Alert"
        content.body = "\(product.name ?? "Product") is running low on stock (\(product.quantity) remaining)"
        content.sound = .default
        
        // Create a unique identifier for this notification
        let identifier = "low-stock-\(product.objectID.uriRepresentation().absoluteString)"
        
        // Remove any existing notification for this product
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        // Schedule new notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func checkLowStockProducts(products: [Product]) {
        for product in products {
            if product.quantity <= product.lowStockThreshold {
                scheduleLowStockNotification(for: product)
            }
        }
    }
} 