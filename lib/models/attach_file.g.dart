// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attach_file.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttachFileAdapter extends TypeAdapter<AttachFile> {
  @override
  final int typeId = 10;

  @override
  AttachFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttachFile(
      id: fields[0] as String,
      filename: fields[1] as String,
      fileType: fields[2] as String,
      contentType: fields[3] as String?,
      previewUrl: fields[4] as String?,
      downloadUrl: fields[5] as String?,
      localPath: fields[6] as String?,
      serverId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AttachFile obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filename)
      ..writeByte(2)
      ..write(obj.fileType)
      ..writeByte(3)
      ..write(obj.contentType)
      ..writeByte(4)
      ..write(obj.previewUrl)
      ..writeByte(5)
      ..write(obj.downloadUrl)
      ..writeByte(6)
      ..write(obj.localPath)
      ..writeByte(7)
      ..write(obj.serverId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttachFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
