// lib/models/user_model.dart
class UserModel {
  final String name;
  final String recoveryHash;
  final bool isNew;

  UserModel({
    required this.name,
    required this.recoveryHash,
    this.isNew = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? json['nickname'] ?? '',
      recoveryHash: json['recovery_hash'] ?? json['visitor_id'] ?? '',
      isNew: json['is_new'] ?? false,
    );
  }

  // Create a guest user
  factory UserModel.guest() {
    return UserModel(
      name: 'Guest',
      recoveryHash: '',
      isNew: false,
    );
  }

  bool get isLoggedIn => recoveryHash.isNotEmpty && name.isNotEmpty && name != 'Guest';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'recovery_hash': recoveryHash,
      'is_new': isNew,
    };
  }
}