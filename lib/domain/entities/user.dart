class Users {
  final String id;
  final String email;
  final String fullName;

  Users({
    required this.id,
    required this.email,
    required this.fullName,
  });

  // Factory constructor để parse JSON
  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      id: json['id'] ?? json['_id'], 
      email: json['email'],
      fullName: json['fullName'],
    );
  }
}