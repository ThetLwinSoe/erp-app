class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final int? companyId;
  final Company? company;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.companyId,
    this.company,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'sale_rep',
      companyId: json['companyId'],
      company: (json['company'] ?? json['Company']) != null
          ? Company.fromJson(json['company'] ?? json['Company'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'companyId': companyId,
    };
  }

  bool get isSaleRep => role == 'sale_rep';
  bool get isAdmin => role == 'admin' || role == 'superadmin';
}

class Company {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String status;
  final String? logo;
  final String currency;

  Company({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    required this.status,
    this.logo,
    required this.currency,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      status: json['status'] ?? 'active',
      logo: json['logo'],
      currency: json['currency'] ?? 'USD',
    );
  }
}
