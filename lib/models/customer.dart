class Customer {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String type;
  final String? customerCode;
  final String? supplierCode;
  final int companyId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.country,
    required this.type,
    this.customerCode,
    this.supplierCode,
    required this.companyId,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      type: json['type'] ?? 'customer',
      customerCode: json['customerCode'],
      supplierCode: json['supplierCode'],
      companyId: json['companyId'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  /// Whichever code is relevant given this customer's role - customerCode for
  /// a customer/both record, supplierCode for a supplier-only record. Codes
  /// are server-generated, never user-editable (see toJson - not included).
  String? get code => isCustomer ? customerCode : supplierCode;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
      'type': type,
    };
  }

  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  bool get isCustomer => type == 'customer' || type == 'both';
  bool get isSupplier => type == 'supplier' || type == 'both';
}
