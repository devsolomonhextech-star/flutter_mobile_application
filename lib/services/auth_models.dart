// Central auth models.
// Keeping these separate avoids circular imports and makes session parsing easier.

class StaffUser {
  final dynamic raw; // Keep flexible until we formalize full Staff schema.

  const StaffUser({required this.raw});

  factory StaffUser.fromJson(dynamic json) {
    return StaffUser(raw: json);
  }

  Map<String, dynamic> get asMap {
    if (raw is Map<String, dynamic>) return raw as Map<String, dynamic>;
    if (raw is Map) return (raw as Map).cast<String, dynamic>();
    return <String, dynamic>{};
  }

  String? get id {
    final m = asMap;
    return m['id']?.toString() ?? m['staffID']?.toString() ?? m['staffId']?.toString();
  }

  String? get staffID => asMap['staffID']?.toString();
   String? get institution => asMap['institution']?.toString();
    String? get phone => asMap['phone']?.toString();
     String? get department => asMap['department']?.toString();
      String? get email => asMap['email']?.toString();
       String? get firstName => asMap['firstName']?.toString();
        String? get lastName => asMap['lastName']?.toString();

  String? get fullName =>
      asMap['fullName']?.toString() ?? asMap['name']?.toString() ?? asMap['username']?.toString();

  String? get roleName =>
      asMap['role']?['name']?.toString() ?? asMap['role']?.toString();
}

