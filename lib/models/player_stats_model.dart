import 'package:hive/hive.dart';

part 'player_stats_model.g.dart';

@HiveType(typeId: 6)
class PlayerStats extends HiveObject {
  @HiveField(0)
  String? backendId;

  @HiveField(1)
  String playerId;

  @HiveField(2)
  String? matchId;

  @HiveField(3)
  double? topSpeed;

  @HiveField(4)
  double? totalDistance;

  @HiveField(5)
  int? goals;

  @HiveField(6)
  int? assists;

  @HiveField(7)
  int? yellowCards;

  @HiveField(8)
  int? redCards;

  @HiveField(9)
  bool? isMvp;

  @HiveField(10)
  double? acquisition;

  @HiveField(11)
  Map<dynamic, dynamic>? actionsDetected;

  @HiveField(12)
  String? heatmapImageUrl;

  PlayerStats({
    this.backendId,
    required this.playerId,
    this.matchId,
    this.topSpeed = 0.0,
    this.totalDistance = 0.0,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.isMvp = false,
    this.acquisition = 0.0,
    this.actionsDetected,
    this.heatmapImageUrl,
  });
}
