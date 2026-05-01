import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/pages_details/details_player.dart';
import 'package:offside/services/sync_service.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  final playersBox = Hive.box<Player>('players');
  String searchQuery = "";
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _refreshPlayers();
  }

  Future<void> _refreshPlayers() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    await SyncService.fetchAllLeaguesFromBackend();
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Players"),
        actions: [
          if (_isSyncing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshPlayers,
            ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: playersBox.listenable(),
          builder: (context, box, _) {
            final players = playersBox.values
                .where((p) =>
                    p.name.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Column(
              children: [
                // ===== Search Bar =====
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (val) => setState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search players...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                if (_isSyncing && players.isEmpty)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),

                // ===== Players List =====
                if (!_isSyncing || players.isNotEmpty)
                  Expanded(
                    child: players.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_search,
                                    size: 64,
                                    color: colorScheme.outline.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                const Text("No players found"),
                                TextButton(
                                  onPressed: _refreshPlayers,
                                  child: const Text("Sync Data"),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshPlayers,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: players.length,
                              itemBuilder: (context, index) {
                                final player = players[index];
                                const Color navy = Color(0xFF0D1956);

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PlayerDetailsPage(player: player),
                                        ),
                                      );
                                    },
                                    leading: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: navy,
                                      backgroundImage: (player.image != null &&
                                              player.image!.isNotEmpty)
                                          ? AssetImage(player.image!)
                                          : null,
                                      child: (player.image == null ||
                                              player.image!.isEmpty)
                                          ? const Icon(Icons.person,
                                              color: Colors.white, size: 30)
                                          : null,
                                    ),
                                    title: Text(
                                      player.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    subtitle: Text(
                                      "${player.position} • Jersey #${player.number}",
                                      style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6)),
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
