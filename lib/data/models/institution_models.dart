// lib/data/models/institution_models.dart
class Institution {
  final String? id;
  final String? name;
  final String? code;
  final String? address;
  final String? phone;
  final String? email;

  Institution({
    this.id,
    this.name,
    this.code,
    this.address,
    this.phone,
    this.email,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'] as String?,
      name: json['name'] as String?,
      code: json['code'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
    };
  }
}

