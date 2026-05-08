// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_stats_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MatchStatsAdapter extends TypeAdapter<MatchStats> {
  @override
  final int typeId = 5;

  @override
  MatchStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MatchStats(
      backendId: fields[0] as String?,
      matchId: (fields[1] as String?) ?? '',
      teamId: (fields[2] as String?) ?? '',
      passesCount: (fields[3] as num?)?.toInt() ?? 0,
      goalCount: (fields[4] as num?)?.toInt() ?? 0,
      foulCount: (fields[5] as num?)?.toInt() ?? 0,
      yellowCardCount: (fields[6] as num?)?.toInt() ?? 0,
      redCardCount: (fields[7] as num?)?.toInt() ?? 0,
      goalkeeperSaves: (fields[8] as num?)?.toInt() ?? 0,
      cornerCount: (fields[9] as num?)?.toInt() ?? 0,
      mvpName: fields[10] as String?,
      ownGoals: (fields[11] as num?)?.toInt() ?? 0,
      freeKicks: (fields[12] as num?)?.toInt() ?? 0,
      acquisitionAvg: (fields[13] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, MatchStats obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.backendId)
      ..writeByte(1)
      ..write(obj.matchId)
      ..writeByte(2)
      ..write(obj.teamId)
      ..writeByte(3)
      ..write(obj.passesCount)
      ..writeByte(4)
      ..write(obj.goalCount)
      ..writeByte(5)
      ..write(obj.foulCount)
      ..writeByte(6)
      ..write(obj.yellowCardCount)
      ..writeByte(7)
      ..write(obj.redCardCount)
      ..writeByte(8)
      ..write(obj.goalkeeperSaves)
      ..writeByte(9)
      ..write(obj.cornerCount)
      ..writeByte(10)
      ..write(obj.mvpName)
      ..writeByte(11)
      ..write(obj.ownGoals)
      ..writeByte(12)
      ..write(obj.freeKicks)
      ..writeByte(13)
      ..write(obj.acquisitionAvg);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
