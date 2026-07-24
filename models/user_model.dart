enum UserRole { pembeli, penjual }

extension UserRoleX on UserRole {
  String get value => this == UserRole.pembeli ? 'pembeli' : 'penjual';

  static UserRole fromString(String value) {
    switch (value) {
      case 'pembeli':
        return UserRole.pembeli;
      case 'penjual':
        return UserRole.penjual;
      default:
        throw ArgumentError('Unknown role: $value');
    }
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? phone;
  final String? profileImageUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      role: UserRoleX.fromString(map['role'] as String),
      phone: map['phone'] as String?,
      profileImageUrl: map['profile_image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
