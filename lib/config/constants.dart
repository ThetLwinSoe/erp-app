class AppConstants {
  // API Configuration - Update this to your ERP system URL
  static const String baseUrl = 'http://localhost:3000/api'; // Web / iOS simulator
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String baseUrl = 'http://YOUR_SERVER_IP:3000/api'; // Physical device

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;

  // Sale Status
  static const List<String> saleStatuses = [
    'pending',
    'confirmed',
    'shipped',
    'delivered',
    'cancelled',
  ];

  // Status Colors
  static const Map<String, int> statusColors = {
    'pending': 0xFFFFA726,
    'confirmed': 0xFF42A5F5,
    'shipped': 0xFF7E57C2,
    'delivered': 0xFF66BB6A,
    'cancelled': 0xFFEF5350,
  };

  // App Info
  static const String appName = 'ERP Sales App';
  static const String appVersion = '1.0.0';
}
