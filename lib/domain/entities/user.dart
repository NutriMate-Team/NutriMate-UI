class Users {
  final String id;
  final String email;
  final String fullName;
  final String? profilePictureUrl;

  Users({
    required this.id,
    required this.email,
    required this.fullName,
    this.profilePictureUrl,
  });

  // Factory constructor để parse JSON
  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      id: json['id'] ?? json['_id'], 
      email: json['email'],
      fullName: json['fullName'] ?? 'User',
      profilePictureUrl: json['profilePictureUrl'],
    );
  }
}