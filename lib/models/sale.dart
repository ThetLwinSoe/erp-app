import 'customer.dart';
import 'product.dart';
import 'user.dart';

class Sale {
  final int id;
  final int customerId;
  final int userId;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double tax;
  final double total;
  final String? notes;
  final int companyId;
  final Customer? customer;
  final User? user;
  final List<SaleItem>? items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Sale({
    required this.id,
    required this.customerId,
    required this.userId,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    this.discountPercent = 0,
    this.discountAmount = 0,
    required this.tax,
    required this.total,
    this.notes,
    required this.companyId,
    this.customer,
    this.user,
    this.items,
    this.createdAt,
    this.updatedAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      customerId: json['customerId'] ?? 0,
      userId: json['userId'] ?? 0,
      orderNumber: json['orderNumber'] ?? '',
      status: json['status'] ?? 'pending',
      subtotal: _parseDouble(json['subtotal']),
      discountPercent: _parseDouble(json['discountPercent']),
      discountAmount: _parseDouble(json['discountAmount']),
      tax: _parseDouble(json['tax']),
      total: _parseDouble(json['total']),
      notes: json['notes'],
      companyId: json['companyId'] ?? 0,
      customer: (json['customer'] ?? json['Customer']) != null
          ? Customer.fromJson(json['customer'] ?? json['Customer'])
          : null,
      user: (json['user'] ?? json['User']) != null
          ? User.fromJson(json['user'] ?? json['User'])
          : null,
      items: (json['items'] ?? json['SaleItems']) != null
          ? ((json['items'] ?? json['SaleItems']) as List).map((item) => SaleItem.fromJson(item)).toList()
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

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isShipped => status == 'shipped';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get canEdit => isPending;
  bool get canCancel => isPending || isConfirmed;
}

class SaleItem {
  final int id;
  final int saleId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double discountPercent;
  final double discountAmount;
  final double total;
  final Product? product;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0,
    this.discountAmount = 0,
    required this.total,
    this.product,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] ?? 0,
      saleId: json['saleId'] ?? 0,
      productId: json['productId'] ?? 0,
      quantity: json['quantity'] ?? 0,
      unitPrice: _parseDouble(json['unitPrice']),
      discountPercent: _parseDouble(json['discountPercent']),
      discountAmount: _parseDouble(json['discountAmount']),
      total: _parseDouble(json['total']),
      product: (json['product'] ?? json['Product']) != null
          ? Product.fromJson(json['product'] ?? json['Product'])
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercent': discountPercent,
    };
  }
}

class CreateSaleRequest {
  final int customerId;
  final double tax;
  final double discountPercent;
  final String? notes;
  final List<CreateSaleItemRequest> items;

  CreateSaleRequest({
    required this.customerId,
    this.tax = 0,
    this.discountPercent = 0,
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'tax': tax,
      'discountPercent': discountPercent,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CreateSaleItemRequest {
  final int productId;
  final int quantity;
  final double unitPrice;
  final double discountPercent;

  CreateSaleItemRequest({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercent': discountPercent,
    };
  }
}
