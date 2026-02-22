// lib/models/room_model.dart
class RoomModel {
  final String code;
  final int participants;
  final String lastActive;
  final String nickname;
  final String status;
  final String logoPath;
  final int userLimits;

  RoomModel({
    required this.code,
    required this.participants,
    required this.lastActive,
    required this.nickname,
    required this.status,
    required this.logoPath,
    required this.userLimits,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      code: json['code'] ?? '',
      participants: json['participants'] ?? 0,
      lastActive: json['last_active'] ?? '',
      nickname: json['nickname'] ?? '',
      status: json['status'] ?? 'private',
      logoPath: json['logo_path'] ?? 'assets/default_logo.jpg',
      userLimits: json['user_limits'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'participants': participants,
      'last_active': lastActive,
      'nickname': nickname,
      'status': status,
      'logo_path': logoPath,
      'user_limits': userLimits,
    };
  }

  bool get isPublic => status.toLowerCase() == 'public';
  bool get hasLogo => logoPath.isNotEmpty;
  String get roomStatusIcon => isPublic ? '🌐' : '🔒';
  String get participantDisplay => participants == 1 ? '1 user' : '$participants users';
}