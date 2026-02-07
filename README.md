# ERP Sales Mobile App

A Flutter mobile application for Sales Representatives to perform sales operations, integrated with the ERP System.

## Features

- **Authentication**: Secure login with JWT tokens
- **Dashboard**: Overview of sales statistics and quick actions
- **Sales Management**: Create, view, update, and track sales orders
- **Customer Management**: View and add customers
- **Product Catalog**: Browse products with stock information
- **Sales Reports**: View sales performance with date range filtering

## Requirements

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- ERP System backend running on port 3000

## Setup

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure API URL**:
   Edit `lib/config/constants.dart` and update the `baseUrl`:
   ```dart
   // For Android Emulator
   static const String baseUrl = 'http://10.0.2.2:3000/api';

   // For iOS Simulator
   static const String baseUrl = 'http://localhost:3000/api';

   // For Physical Device (use your server IP)
   static const String baseUrl = 'http://YOUR_SERVER_IP:3000/api';
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── config/
│   ├── constants.dart      # App configuration
│   └── theme.dart          # UI theme
├── models/
│   ├── user.dart           # User model
│   ├── customer.dart       # Customer model
│   ├── product.dart        # Product model
│   └── sale.dart           # Sale model
├── providers/
│   ├── auth_provider.dart      # Authentication state
│   ├── sales_provider.dart     # Sales state
│   ├── customer_provider.dart  # Customer state
│   └── product_provider.dart   # Product state
├── services/
│   ├── api_service.dart        # HTTP client
│   ├── auth_service.dart       # Auth API calls
│   ├── sales_service.dart      # Sales API calls
│   ├── customer_service.dart   # Customer API calls
│   └── product_service.dart    # Product API calls
├── screens/
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── dashboard_screen.dart
│   ├── sales/
│   ├── customers/
│   ├── products/
│   └── reports/
└── main.dart
```

## API Integration

The app integrates with the ERP System backend API:

- `POST /api/auth/login` - User authentication
- `GET /api/auth/me` - Get current user
- `GET /api/sales` - List sales (filtered for Sale Rep)
- `POST /api/sales` - Create new sale
- `GET /api/sales/:id` - Get sale details
- `PATCH /api/sales/:id/status` - Update sale status
- `GET /api/customers` - List customers
- `POST /api/customers` - Create customer
- `GET /api/products` - List products
- `GET /api/reports/sales` - Sales report

## Sale Rep Permissions

Sale Representatives have limited access:
- Can only view/manage their own sales
- Can view customers and products
- Cannot access purchases, inventory adjustments
- Sales reports are filtered to their transactions

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## License

Proprietary - Internal use only
