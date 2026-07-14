// lib/data/models/patient_models.dart
class Patient {
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? gender;
  final int? age;
  final String? bloodType;
  final Insurance? insurance;

  Patient({
    this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.gender,
    this.age,
    this.bloodType,
    this.insurance,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      bloodType: json['bloodType'] as String?,
      insurance: json['insurance'] != null ? Insurance.fromJson(json['insurance']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'gender': gender,
      'age': age,
      'bloodType': bloodType,
      'insurance': insurance?.toJson(),
    };
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  String get initials {
    final first = firstName?.isNotEmpty == true ? firstName![0] : '';
    final last = lastName?.isNotEmpty == true ? lastName![0] : '';
    return '$first$last'.toUpperCase();
  }
}

class Insurance {
  final String? id;
  final String? name;
  final String? policyNumber;

  Insurance({
    this.id,
    this.name,
    this.policyNumber,
  });

  factory Insurance.fromJson(Map<String, dynamic> json) {
    return Insurance(
      id: json['id'] as String?,
      name: json['name'] as String?,
      policyNumber: json['policyNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'policyNumber': policyNumber,
    };
  }
}