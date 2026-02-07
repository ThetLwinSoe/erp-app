class Product {
  final int id;
  final String sku;
  final String name;
  final String? description;
  final String? category;
  final String? unit;
  final double costPrice;
  final double sellingPrice;
  final int companyId;
  final Inventory? inventory;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    this.description,
    this.category,
    this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.companyId,
    this.inventory,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'],
      unit: json['unit'],
      costPrice: _parseDouble(json['costPrice']),
      sellingPrice: _parseDouble(json['sellingPrice']),
      companyId: json['companyId'] ?? 0,
      inventory: (json['inventory'] ?? json['Inventory']) != null
          ? Inventory.fromJson(json['inventory'] ?? json['Inventory'])
          : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int get stockQuantity => inventory?.quantity ?? 0;
  bool get isLowStock => inventory != null && inventory!.quantity <= inventory!.minStockLevel;
  bool get isInStock => stockQuantity > 0;
}

class Inventory {
  final int id;
  final int productId;
  final int quantity;
  final String? location;
  final int minStockLevel;
  final DateTime? lastRestocked;
  final int companyId;

  Inventory({
    required this.id,
    required this.productId,
    required this.quantity,
    this.location,
    required this.minStockLevel,
    this.lastRestocked,
    required this.companyId,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'],
      productId: json['productId'] ?? 0,
      quantity: json['quantity'] ?? 0,
      location: json['location'],
      minStockLevel: json['minStockLevel'] ?? 0,
      lastRestocked: json['lastRestocked'] != null ? DateTime.parse(json['lastRestocked']) : null,
      companyId: json['companyId'] ?? 0,
    );
  }
}
