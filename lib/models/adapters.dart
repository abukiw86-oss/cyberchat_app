// lib/models/adapters.dart
import 'package:hive/hive.dart';
import 'user_model.dart';
import 'rooms_model.dart';
import 'message_model.dart';

part 'adapters.g.dart';

@HiveType(typeId: 0)
class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    return UserModel(
      id: reader.readInt(),
      name: reader.readString(),
      recoveryPhrase: reader.readString(),
      recoveryHash: reader.readString(),
      userLogo: reader.readString(),
      bio: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isNew: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer.writeInt(obj.id ?? 0);
    writer.writeString(obj.name ?? '');
    writer.writeString(obj.recoveryPhrase ?? '');
    writer.writeString(obj.recoveryHash ?? '');
    writer.writeString(obj.userLogo ?? '');
    writer.writeString(obj.bio ?? '');
    writer.writeInt(obj.createdAt?.millisecondsSinceEpoch ?? 0);
    writer.writeBool(obj.isNew);
  }
}

@HiveType(typeId: 1)
class RoomModelAdapter extends TypeAdapter<RoomModel> {
  @override
  final int typeId = 1;

  @override
  RoomModel read(BinaryReader reader) {
    return RoomModel(
      code: reader.readString(),
      participants: reader.readInt(),
      lastActive: DateTime.fromMillisecondsSinceEpoch(reader.readInt()).toIso8601String(),
      nickname: reader.readString(),
      status: reader.readString(),
      logoPath: reader.readString(),
      userLimits:reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, RoomModel obj) {
    writer.writeString(obj.code);
    writer.writeInt(obj.participants);
    writer.writeInt(DateTime.parse(obj.lastActive).millisecondsSinceEpoch);
    writer.writeString(obj.nickname!);
    writer.writeString(obj.status);
    writer.writeString(obj.logoPath!);
    // writer.writeString(obj.userLimits);
  }
}

@HiveType(typeId: 2)
class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final int typeId = 2;

  @override
  MessageModel read(BinaryReader reader) {
    return MessageModel(
      id: reader.readInt(),
      nickname: reader.readString(),
      message: reader.readString(),
      filePath: reader.readString(),
      filePaths: reader.readStringList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()).toIso8601String(),
      visitorHash: reader.readString(),
      userLogo: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.nickname);
    writer.writeString(obj.message);
    writer.writeString(obj.filePath ?? '');
    writer.writeStringList(obj.filePaths);
    writer.writeInt(DateTime.parse(obj.createdAt).millisecondsSinceEpoch);
    writer.writeString(obj.visitorHash);
    writer.writeString(obj.userLogo ?? '');
  }
}