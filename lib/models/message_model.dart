class MessageModel {
  final int id;
  final String nickname;
  final String message;
  final String? filePath;
  final List<String> filePaths;
  final String createdAt;
  final String visitorHash;
  final String? userLogo;

  MessageModel({
    required this.id,
    required this.nickname,
    required this.message,
    this.filePath,
    this.filePaths = const [],
    required this.createdAt,
    required this.visitorHash,
    this.userLogo,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      nickname: json['nickname'] ?? '',
      message: json['message'] ?? '',
      filePath: json['file_path'],
      filePaths: json['file_paths'] != null 
          ? List<String>.from(json['file_paths']) 
          : (json['file_path'] != null ? [json['file_path']] : []),
      createdAt: json['created_at'] ?? '',
      visitorHash: json['visitor_hash'] ?? '',
      userLogo: json['user_logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'message': message,
      'file_path': filePath,
      'file_paths': filePaths,
      'created_at': createdAt,
      'visitor_hash': visitorHash,
      'user_logo': userLogo,
    };
  }
}