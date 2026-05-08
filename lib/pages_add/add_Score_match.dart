import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/event_model.dart';
import 'package:offside/services/sync_service.dart';
import 'package:offside/services/api_service.dart';
import 'package:offside/theme_provider.dart';

class AddScorePage extends StatefulWidget {
  final int matchIndex;
  final int leagueIndex;

  const AddScorePage({
    super.key,
    required this.matchIndex,
    required this.leagueIndex,
  });

  @override
  State<AddScorePage> createState() => _AddScorePageState();
}

class _AddScorePageState extends State<AddScorePage> {
  final leaguesBox = Hive.box<League>('leagues');
  late League league;

  @override
  void initState() {
    super.initState();
    league = leaguesBox.getAt(widget.leagueIndex)!;
  }

  void _addEvent(Match2 match, bool isHome, String type, Player player,
      {String? assist}) {
    final event = Event(
      type: type,
      player: player.name,
      minute: DateTime.now().minute,
      assist: assist,
    );

    if (isHome) {
      match.eventsHome = [...match.eventsHome, event];
    } else {
      match.eventsAway = [...match.eventsAway, event];
    }

    league.save();
    setState(() {});
  }

  Future<void> _finishMatch(Match2 match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Finish Match?"),
        content: Text(
          "Final Score: ${match.homeTeamScore ?? 0} - ${match.awayTeamScore ?? 0}\n\nThis will push the result to the backend.",
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Finish & Sync")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SyncService.syncMatchResult(match, league, isFinished: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Match result synced to backend!"),
            backgroundColor: AppColors.darkPrimary,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️  Result saved locally but sync failed: ${e.message}"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showAssistDialog(Player scorer, Match2 match, bool isHome) {
    final players = isHome ? match.homeTeam.players : match.awayTeam.players;
    final availablePlayers = players.where((p) => p != scorer).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? AppColors.darkBg 
          : Colors.grey[100],
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Assist Player",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: availablePlayers.length,
                  itemBuilder: (context, index) {
                    final p = availablePlayers[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.person, color: AppColors.darkSecondary),
                        title: Text(p.name),
                        subtitle: Text(
                          "Assists: ${p.assists} | Passes: ${p.passes}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () {
                          setState(() {
                            p.assists++;
                            p.passes++;
                            p.appearances++;
                            league.save();
                          });
                          _addEvent(match, isHome, "Goal", scorer,
                              assist: p.name);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    _addEvent(match, isHome, "Goal", scorer);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text("No Assist"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEventDialog(Player player, Match2 match, bool isHome) {
    final events = [
      {
        "label": "Goal",
        "icon": Icons.sports_soccer,
        "color": AppColors.darkPrimary,
        "action": () {
          setState(() {
            if (isHome) {
              match.homeTeamScore = (match.homeTeamScore ?? 0) + 1;
            } else {
              match.awayTeamScore = (match.awayTeamScore ?? 0) + 1;
            }
            player.goals++;
            player.shots++;
            player.appearances++;
            league.save();
          });
          _showAssistDialog(player, match, isHome);
        }
      },
      {
        "label": "Yellow Card",
        "icon": Icons.square,
        "color": Colors.yellow[700],
        "action": () {
          setState(() {
            player.yellowCards++;
            league.save();
          });
          _addEvent(match, isHome, "Yellow Card", player);
        }
      },
      {
        "label": "Red Card",
        "icon": Icons.square,
        "color": Colors.red,
        "action": () {
          setState(() {
            player.redCards++;
            league.save();
          });
          _addEvent(match, isHome, "Red Card", player);
        }
      },
      {
        "label": "Shot",
        "icon": Icons.sports,
        "color": Colors.blue,
        "action": () {
          setState(() {
            player.shots++;
            league.save();
          });
          _addEvent(match, isHome, "Shot", player);
        }
      },
      {
        "label": "Substitution",
        "icon": Icons.compare_arrows,
        "color": Colors.orange,
        "action": () {
          _addEvent(match, isHome, "Substitution", player);
        }
      },
      {
        "label": "Offside",
        "icon": Icons.flag,
        "color": Colors.purple,
        "action": () {
          _addEvent(match, isHome, "Offside", player);
        }
      },
      {
        "label": "Corner Kick",
        "icon": Icons.sports_soccer_outlined,
        "color": AppColors.darkPrimary,
        "action": () {
          _addEvent(match, isHome, "Corner Kick", player);
        }
      },
      {
        "label": "Free Kick",
        "icon": Icons.sports,
        "color": Colors.indigo,
        "action": () {
          _addEvent(match, isHome, "Free Kick", player);
        }
      },
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? AppColors.darkBg 
          : Colors.grey[100],
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5,
          child: GridView.count(
            crossAxisCount: 3,
            children: events.map((e) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  (e["action"] as void Function())();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: e["color"] as Color? ?? Colors.grey,
                      child: Icon(
                        e["icon"] as IconData,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e["label"] as String,
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = league.matches[widget.matchIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Details"),
        actions: [
          TextButton.icon(
            onPressed: () => _finishMatch(match),
            icon: Icon(Icons.check_circle, color: primary),
            label: Text(
              "Finish",
              style: TextStyle(color: primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Image.asset(match.homeTeam.logo, width: 50, height: 50),
                    Text(match.homeTeam.name),
                  ],
                ),
                const SizedBox(width: 20),
                Text(
                  "${match.homeTeamScore ?? 0} : ${match.awayTeamScore ?? 0}",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Image.asset(match.awayTeam.logo, width: 50, height: 50),
                    Text(match.awayTeam.name),
                  ],
                ),
              ],
            ),
          ),
          const Divider(thickness: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    children: match.homeTeam.players.map((player) {
                      return Card(
                        child: ListTile(
                          title: Text(player.name),
                          subtitle: Text(
                              "Goals: ${player.goals} | Assists: ${player.assists}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                _showEventDialog(player, match, true),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: match.awayTeam.players.map((player) {
                      return Card(
                        child: ListTile(
                          title: Text(player.name),
                          subtitle: Text(
                              "Goals: ${player.goals} | Assists: ${player.assists}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                _showEventDialog(player, match, false),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
