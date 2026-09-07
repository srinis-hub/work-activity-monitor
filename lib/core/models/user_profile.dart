class UserProfile {
  final String userId;
  final String organizationId;

  final String name;
  final String email;

  final String role;

  UserProfile({
    required this.userId,
    required this.organizationId,
    required this.name,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'organizationId': organizationId,
      'name': name,
      'email': email,
      'role': role,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'employee',
    );
  }
}