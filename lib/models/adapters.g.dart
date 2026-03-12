// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adapters.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapterAdapter extends TypeAdapter<UserModelAdapter> {
  @override
  final int typeId = 0;

  @override
  UserModelAdapter read(BinaryReader reader) {
    return UserModelAdapter();
  }

  @override
  void write(BinaryWriter writer, UserModelAdapter obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RoomModelAdapterAdapter extends TypeAdapter<RoomModelAdapter> {
  @override
  final int typeId = 1;

  @override
  RoomModelAdapter read(BinaryReader reader) {
    return RoomModelAdapter();
  }

  @override
  void write(BinaryWriter writer, RoomModelAdapter obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomModelAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageModelAdapterAdapter extends TypeAdapter<MessageModelAdapter> {
  @override
  final int typeId = 2;

  @override
  MessageModelAdapter read(BinaryReader reader) {
    return MessageModelAdapter();
  }

  @override
  void write(BinaryWriter writer, MessageModelAdapter obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModelAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
