# Inventory & Sales Tracker for Small Restaurants

---

## Project Overview

This project is a lightweight inventory and sales management app for small restaurants, supporting offline use, low-stock alerts, and sales analytics. It helps business owners efficiently manage daily inventory and sales data, with features like real-time stock tracking, sales recording, and visual reporting. The app includes multi-user role-based access control and CSV export functionality.

---

## Features

### Core Functionality
- **Product Management** (CRUD operations, low-stock red alerts)
- **Sales Entry** (auto-decrement inventory, auto-calculate sales amount)
- **Sales History** and trend analytics (charts)
- **Local Notifications** for low-stock alerts
- **Multi-tab Navigation** (Inventory, Sales, History, Reports, Settings)

### Multi-User Role System
- **Manager**: Full access to all features including user management and reports
- **Staff**: Read-only access to inventory management only
- **Cashier**: Access to sales recording and sales history only

### Advanced Features
- **User Management** (add, edit, delete users - Manager only)
- **CSV Export** (sales and inventory reports - Manager only)
- **Role-based UI** (dynamic tab visibility based on user role)
- **Enhanced Error Handling** (friendly error messages with auto-dismiss)
- **Dark Mode** and dynamic type support
- **Offline Capability** (local Core Data storage)

---

## Tech Stack

- **SwiftUI** (iOS 16+/macOS 13+)
- **Core Data** (local data persistence)
- **Swift Charts** (data visualization)
- **UNUserNotificationCenter** (local notifications)

---

## Data Model

### Core Entities
- **Product**
  - name: String
  - quantity: Int32
  - purchasePrice: Double
  - sellingPrice: Double
  - lowStockThreshold: Int32
  - sales: [SaleRecord]

- **SaleRecord**
  - date: Date
  - quantity: Int32
  - totalPrice: Double
  - product: Product

- **User**
  - username: String
  - password: String
  - role: String (Manager/Staff/Cashier)

---

## User Roles & Permissions

| Feature / Role      | Manager | Staff | Cashier |
|---------------------|:-------:|:-----:|:-------:|
| Inventory Management|   ✔️    | Read-only |   ❌    |
| Record Sales        |   ✔️    |   ❌   |   ✔️    |
| Sales History       |   ✔️    |   ❌   |   ✔️    |
| Reports/Analytics   |   ✔️    |   ❌   |   ❌    |
| User Management     |   ✔️    |   ❌   |   ❌    |
| Settings            |   ✔️    |   ✔️   |   ✔️    |

**Legend:** ✔️ = Full access, Read-only = View only, ❌ = No access

---

## Main Screens

- **WelcomeView**: Multi-user login screen with role-based authentication
- **MainTabView**: Dynamic navigation based on user role
  - **InventoryView**: Product list & management (Manager/Staff)
  - **SalesView**: Sales entry (Manager/Cashier)
  - **SalesHistoryView**: Sales history (Manager/Cashier)
  - **ReportsView**: Sales trends & inventory charts with CSV export (Manager only)
  - **SettingsView**: Settings with user management (Manager only)
- **UserManagementView**: User CRUD operations (Manager only)

---

## Default Users

The app automatically creates three default users on first launch:

| Username | Password   | Role    |
|----------|------------|---------|
| manager  | manager123 | Manager |
| staff    | staff123   | Staff   |
| cashier  | cashier123 | Cashier |

---

## How to Run

1. Open `693_small_restaurant.xcodeproj` with Xcode 16+
2. Select the main target `693_small_restaurant` and choose a Mac/iOS device or simulator
3. Build & Run
4. On first launch, enable local notification permissions in the Settings tab
5. Login with any of the default users above

---

## Key Features

### Multi-User Authentication
- Secure login with username/password validation
- Role-based access control throughout the app
- User management interface for administrators
- Session management with automatic logout

### Enhanced UI/UX
- Friendly error messages with auto-dismiss
- Form validation with real-time feedback
- Loading states for async operations
- Confirmation dialogs for destructive actions
- Role-based UI elements (buttons, tabs, features)

### Data Export
- CSV export for sales trends and inventory status
- Share functionality for reports
- Manager-only access to export features

### Notifications & Adaptation
- Low-stock products automatically trigger local notifications (authorization required)
- Supports dark mode and dynamic type
- Compatible with macOS/iOS (some controls like keyboardType are iOS-only)

---

## Directory Structure

```
693_small_restaurant/
├── Views/
│   ├── WelcomeView.swift          # Login screen
│   ├── MainTabView.swift          # Dynamic navigation
│   ├── InventoryView.swift        # Product management
│   ├── SalesView.swift           # Sales entry
│   ├── SalesHistoryView.swift    # Sales history
│   ├── ReportsView.swift         # Analytics & export
│   ├── SettingsView.swift        # Settings & user management
│   ├── UserManagementView.swift  # User CRUD operations
│   └── ProductFormView.swift     # Product add/edit form
├── Managers/
│   └── NotificationManager.swift  # Local notifications
├── 693_small_restaurantApp.swift # App entry point
└── 693_small_restaurant.xcdatamodeld/ # Core Data model
```

---

## Development Notes

- **Core Data**: Local storage with automatic initial user creation
- **SwiftUI**: Modern declarative UI with role-based conditional rendering
- **Security**: Basic authentication with role-based permissions
- **Export**: CSV generation with system share functionality
- **Error Handling**: Comprehensive error messages and validation

---

## Future Enhancements

- PDF report export
- Cloud synchronization
- Advanced analytics and forecasting
- Barcode scanning for inventory
- Multi-platform support (Android, Web)
- API integration for external systems
