// lib/models/rooms_model.dart
class RoomModel {
  final String code;
  final int participants;
  final String lastActive;
  final String nickname;
  final String status;
  final String logoPath;
  final String userLimits;

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
    // Safe integer parser
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    // Safe string parser
    String toString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    return RoomModel(
      code: toString(json['code']),
      participants: toInt(json['participants']),
      lastActive: toString(json['last_active']),
      nickname: toString(json['nickname']),
      status: toString(json['status']).toLowerCase(),
      logoPath: toString(json['logo_path']),
      userLimits: toString(json['user_limits']),
    );
  }

  // ✅ ADD THIS METHOD
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
  bool get haslogo => logoPath.isNotEmpty && logoPath != 'null' && logoPath != '';
  String get roomStatusIcon => isPublic ? '🌐' : '🔒';
  String get participantDisplay => participants == 1 ? '1 user' : '$participants users';
}