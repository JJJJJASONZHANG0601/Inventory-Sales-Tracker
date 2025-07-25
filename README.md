# Small Restaurant Inventory & Sales Management App

## Overview

This app is a lightweight inventory, sales, purchasing, and supplier management system designed for small restaurants. It supports offline use, low-stock alerts, multi-user roles, and detailed analytics. The app enables business owners to efficiently manage products, suppliers, purchase orders, sales, and users, with robust role-based access control and CSV export capabilities.

---

## Features

### Core Modules

- **Product Management**: Add, edit, delete, and view products. Low-stock alerts and inventory tracking.
- **Sales Management**: Record sales, auto-decrement inventory, and view sales history.
- **Purchase Order Management**: Record and manage purchase orders, link to suppliers and products, and update inventory.
- **Supplier Management**: Add, edit, delete, and view suppliers. View purchase history per supplier.
- **Reports & Analytics**: Visualize sales trends and inventory status. Export detailed data as CSV.
- **User Management**: Add, edit, and delete users (Manager only).
- **Role-Based UI**: Dynamic tab visibility and feature access based on user role.
- **Notifications**: Local notifications for low-stock products.
- **Import/Export**: CSV export for products, sales, purchase orders, and suppliers.
- **Sorting & Filtering**: Sort and search in all major lists.

### User Roles

- **Manager**: Full access to all features, including user, supplier, and purchase order management, and reports.
- **Staff**: Read-only access to inventory.
- **Cashier**: Access to sales entry and sales history.

---

## Tech Stack

- **SwiftUI** (iOS 16+/macOS 13+)
- **Core Data** (local data persistence)
- **Swift Charts** (data visualization)
- **UNUserNotificationCenter** (local notifications)

---

## Data Model

### Entities

- **Product**
  - name: String
  - quantity: Int32
  - purchasePrice: Double
  - sellingPrice: Double
  - lowStockThreshold: Int32
  - purchaseOrders: [PurchaseOrder]
  - sales: [SaleRecord]

- **Supplier**
  - name: String
  - contactInfo: String
  - address: String
  - notes: String
  - purchaseOrders: [PurchaseOrder]

- **PurchaseOrder**
  - product: Product
  - supplier: Supplier
  - quantity: Int32
  - purchasePrice: Double
  - purchaseDate: Date

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

| Feature / Role      | Manager | Staff      | Cashier   |
|---------------------|:-------:|:----------:|:---------:|
| Inventory           |   ✔️    | Read-only  |     ❌    |
| Sales Entry         |   ✔️    |     ❌     |    ✔️     |
| Sales History       |   ✔️    |     ❌     |    ✔️     |
| Purchase Orders     |   ✔️    |     ❌     |    ❌     |
| Suppliers           |   ✔️    |     ❌     |    ❌     |
| Reports/Analytics   |   ✔️    |     ❌     |    ❌     |
| User Management     |   ✔️    |     ❌     |    ❌     |
| Settings            |   ✔️    |    ✔️      |    ✔️     |

---

## Main Screens

- **WelcomeView**: Login screen with role-based authentication.
- **MainTabView**: Dynamic tab navigation based on user role.
  - **InventoryView**: Product management (Manager/Staff)
  - **SalesView**: Sales entry (Manager/Cashier)
  - **SalesHistoryView**: Sales history (Manager/Cashier)
  - **PurchaseOrderListView**: Purchase order management (Manager)
  - **SupplierListView**: Supplier management (Manager)
  - **ReportsView**: Analytics and CSV export (Manager)
  - **SettingsView**: App settings and user management (Manager)
- **UserManagementView**: User CRUD (Manager only)
- **ProductFormView**, **SupplierFormView**, **PurchaseOrderFormView**: Add/edit forms

---

## Default Users

| Username | Password   | Role    |
|----------|------------|---------|
| manager  | manager123 | Manager |
| staff    | staff123   | Staff   |
| cashier  | cashier123 | Cashier |

---

## How to Run

1. Open `693_small_restaurant.xcodeproj` in Xcode 16+.
2. Select the main target and a device/simulator.
3. Build & Run.
4. On first launch, enable notification permissions in Settings.
5. Log in with any default user.

---

## Directory Structure

```
693_small_restaurant/
├── Views/
│   ├── WelcomeView.swift
│   ├── MainTabView.swift
│   ├── InventoryView.swift
│   ├── SalesView.swift
│   ├── SalesHistoryView.swift
│   ├── ReportsView.swift
│   ├── SettingsView.swift
│   ├── UserManagementView.swift
│   ├── ProductFormView.swift
│   ├── SupplierListView.swift
│   ├── SupplierFormView.swift
│   ├── SupplierDetailView.swift
│   ├── PurchaseOrderListView.swift
│   ├── PurchaseOrderFormView.swift
├── Managers/
│   └── NotificationManager.swift
├── 693_small_restaurantApp.swift
└── 693_small_restaurant.xcdatamodeld/
```

---

## Development Notes

- **Core Data**: Local storage, automatic initial user creation.
- **SwiftUI**: Modern declarative UI, role-based rendering.
- **Security**: Basic authentication, role-based permissions.
- **Export**: CSV generation and sharing.
- **Error Handling**: Comprehensive validation and user feedback.

---

## Future Enhancements

- PDF report export
- Cloud sync
- Advanced analytics and forecasting
- Barcode scanning for inventory
- Multi-platform support (Android, Web)
- API integration
