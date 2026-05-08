import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/player_stats_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/leage_model.dart';

class PlayerDetailsPage extends StatelessWidget {
  final Player player;

  const PlayerDetailsPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color darkBlue = Color(0xFF0D1956);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: darkBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkBlue, Color(0xFF16246E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white24,
                      backgroundImage: player.image != null && player.image!.isNotEmpty
                          ? (player.image!.startsWith('http') 
                              ? NetworkImage(player.image!) 
                              : AssetImage(player.image!) as ImageProvider)
                          : null,
                      child: (player.image == null || player.image!.isEmpty)
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      player.name,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${player.position} • #${player.number} • ${player.nationality}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBioSection(player),
                  const SizedBox(height: 24),
                  const Text("Career Statistics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildStatsGrid(player),
                  const SizedBox(height: 24),
                  const Text("Recent Matches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildMatchesList(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(Player player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _bioItem("Height", "${player.height?.toInt() ?? '-'} cm"),
        _bioItem("Weight", "${player.weight?.toInt() ?? '-'} kg"),
        _bioItem("Age", "${player.age}"),
      ],
    );
  }

  Widget _bioItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatsGrid(Player player) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _statCard("Appearances", "${player.appearances}", Colors.blue),
        _statCard("Goals", "${player.goals}", Colors.green),
        _statCard("Assists", "${player.assists}", Colors.orange),
        _statCard("Top Speed", "${player.highestSpeed?.toStringAsFixed(1) ?? '0'} km/h", Colors.red),
        _statCard("Yellow Cards", "${player.yellowCards}", Colors.amber),
        _statCard("Red Cards", "${player.redCards}", Colors.redAccent),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMatchesList(BuildContext context) {
    final playerStatsBox = Hive.box<PlayerStats>('player_stats');
    final leaguesBox = Hive.box<League>('leagues');
    
    final pStats = playerStatsBox.values.where((s) => s.playerId == player.backendId).toList();
    
    if (pStats.isEmpty) {
      return const Center(child: Text("No match data available."));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pStats.length,
      itemBuilder: (context, index) {
        final stat = pStats[index];
        Match2? match;
        for (var l in leaguesBox.values) {
          for (var m in l.matches) {
            if (m.backendId == stat.matchId) {
              match = m;
              break;
            }
          }
          if (match != null) break;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(match != null ? "${match.homeTeam.name} vs ${match.awayTeam.name}" : "Match #${stat.matchId}"),

            subtitle: Text("Goals: ${stat.goals} | Assists: ${stat.assists} | MVP: ${(stat.isMvp ?? false) ? 'Yes' : 'No'}"),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _smallStat("Top Speed", "${stat.topSpeed} km/h"),
                        _smallStat("Distance", "${stat.totalDistance} km"),
                        _smallStat("Acquisition", "${stat.acquisition}%"),
                      ],
                    ),
                    if (stat.heatmapImageUrl != null && stat.heatmapImageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text("Match Heatmap", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Image.network(
                        stat.heatmapImageUrl!, 
                        height: 150, 
                        fit: BoxFit.cover, 
                        errorBuilder: (_, __, ___) => const Icon(Icons.map_outlined),
                      ),
                    ]
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _smallStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
