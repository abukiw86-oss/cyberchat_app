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
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      if (value is double) return value.toInt();
      return 0;
    }

    return RoomModel(
      code: json['code'] ?? '',
      participants: toInt(json['participants']),
      lastActive: json['last_active'] ?? '',
      nickname: json['nickname'] ?? '',
      status: json['status'] ?? 'private',
      logoPath: json['logo_path'] ?? '',
      userLimits: toInt(json['user_limits'] ?? json['participant_limit'] ?? 0), 
    );
  }

  bool get isPublic => status.toLowerCase() == 'public';
  bool get hasLogo => logoPath.isNotEmpty;
  String get roomStatusIcon => isPublic ? '🌐' : '🔒';
  String get participantDisplay => participants == 1 ? '1 user' : '$participants users';
}