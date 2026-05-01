// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvitationAdapter extends TypeAdapter<Invitation> {
  @override
  final int typeId = 8;

  @override
  Invitation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Invitation(
      id: fields[0] as String,
      teamName: fields[1] as String,
      leagueName: fields[2] as String,
      playerName: fields[3] as String,
      playerId: fields[4] as String,
      jerseyNumber: fields[5] as int,
      status: fields[6] as String,
      timestamp: fields[7] as DateTime,
      teamId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Invitation obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.teamName)
      ..writeByte(2)
      ..write(obj.leagueName)
      ..writeByte(3)
      ..write(obj.playerName)
      ..writeByte(4)
      ..write(obj.playerId)
      ..writeByte(5)
      ..write(obj.jerseyNumber)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.teamId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvitationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
