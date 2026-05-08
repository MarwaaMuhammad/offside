// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_stats_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerStatsAdapter extends TypeAdapter<PlayerStats> {
  @override
  final int typeId = 6;

  @override
  PlayerStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerStats(
      backendId: fields[0] as String?,
      playerId: (fields[1] as String?) ?? '',
      matchId: fields[2] as String?,
      topSpeed: (fields[3] as num?)?.toDouble() ?? 0.0,
      totalDistance: (fields[4] as num?)?.toDouble() ?? 0.0,
      goals: (fields[5] as num?)?.toInt() ?? 0,
      assists: (fields[6] as num?)?.toInt() ?? 0,
      yellowCards: (fields[7] as num?)?.toInt() ?? 0,
      redCards: (fields[8] as num?)?.toInt() ?? 0,
      isMvp: (fields[9] as bool?) ?? false,
      acquisition: (fields[10] as num?)?.toDouble() ?? 0.0,
      actionsDetected: (fields[11] as Map?)?.cast<dynamic, dynamic>(),
      heatmapImageUrl: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerStats obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.backendId)
      ..writeByte(1)
      ..write(obj.playerId)
      ..writeByte(2)
      ..write(obj.matchId)
      ..writeByte(3)
      ..write(obj.topSpeed)
      ..writeByte(4)
      ..write(obj.totalDistance)
      ..writeByte(5)
      ..write(obj.goals)
      ..writeByte(6)
      ..write(obj.assists)
      ..writeByte(7)
      ..write(obj.yellowCards)
      ..writeByte(8)
      ..write(obj.redCards)
      ..writeByte(9)
      ..write(obj.isMvp)
      ..writeByte(10)
      ..write(obj.acquisition)
      ..writeByte(11)
      ..write(obj.actionsDetected)
      ..writeByte(12)
      ..write(obj.heatmapImageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
