class Role {
  String? id;
  String? name;
  Role({this.id, this.name});
  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(id: json['id'] as String?, name: json['name'] as String?);
  }
}
