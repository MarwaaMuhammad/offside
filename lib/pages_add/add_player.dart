import 'package:flutter/material.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/services/api_service.dart';

class CreatePlayersPage extends StatefulWidget {
  final Team team;
  final String leagueName;
  const CreatePlayersPage({super.key, required this.team, required this.leagueName});

  @override
  State<CreatePlayersPage> createState() => _CreatePlayersPageState();
}

class _CreatePlayersPageState extends State<CreatePlayersPage> {
  final TextEditingController searchController = TextEditingController();
  
  List<dynamic> allAvailablePlayers = [];
  List<dynamic> filteredPlayers = [];
  Map<String, int> selectedPlayersWithJersey = {}; // PlayerID -> JerseyNumber
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlayersFromBackend();
  }

  Future<void> _fetchPlayersFromBackend() async {
    setState(() => _isLoading = true);
    try {
      final players = await ApiService.getAllPlayers();
      setState(() {
        allAvailablePlayers = players;
        filteredPlayers = players;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error fetching players: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      filteredPlayers = allAvailablePlayers
          .where((p) =>
              (p['full_name'] ?? "").toString().toLowerCase().contains(query.toLowerCase()) ||
              (p['email'] ?? "").toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  String _getPlayerId(Map<String, dynamic> player) {
    return (player['player_id'] ?? player['id'] ?? "").toString();
  }

  void _showJerseyDialog(Map<String, dynamic> player) {
    final TextEditingController jerseyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Assign Jersey for ${player['full_name']}"),
        content: TextField(
          controller: jerseyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Jersey Number", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (jerseyController.text.isNotEmpty) {
                setState(() {
                  selectedPlayersWithJersey[_getPlayerId(player)] = int.parse(jerseyController.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Assign"),
          ),
        ],
      ),
    );
  }

  void _confirmPlayers() {
    for (var entry in selectedPlayersWithJersey.entries) {
      final playerMap = allAvailablePlayers.firstWhere(
        (p) => _getPlayerId(p) == entry.key,
        orElse: () => {},
      );
      
      if (playerMap.isNotEmpty) {
        final newPlayer = Player(
          name: playerMap['full_name'] ?? "Unknown",
          position: playerMap['position'] ?? "Unknown",
          age: playerMap['age'] ?? 20,
          nationality: playerMap['nationality'] ?? "Unknown",
          number: entry.value,
          height: (playerMap['height'] as num?)?.toDouble(),
          weight: (playerMap['weight'] as num?)?.toDouble(),
          backendId: entry.key,
        );

        if (!widget.team.players.any((p) => p.backendId == newPlayer.backendId)) {
          widget.team.players.add(newPlayer);
        }
      }
    }

    Navigator.pop(context, widget.team);
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Colors.blue[900]!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Add Players"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text("${selectedPlayersWithJersey.length} Selected", style: const TextStyle(fontWeight: FontWeight.bold))),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: searchController,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: "Search registered players...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: filteredPlayers.isEmpty && !_isLoading
                    ? const Center(child: Text("No players found"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPlayers.length,
                        itemBuilder: (context, index) {
                          final player = filteredPlayers[index];
                          final String pId = _getPlayerId(player);
                          final isSelected = selectedPlayersWithJersey.containsKey(pId);

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(color: isSelected ? primary : Colors.transparent, width: 2),
                            ),
                            child: ListTile(
                              onTap: () => isSelected ? setState(() => selectedPlayersWithJersey.remove(pId)) : _showJerseyDialog(player),
                              leading: CircleAvatar(child: Text((player['full_name'] ?? "?")[0])),
                              title: Text(player['full_name'] ?? "Unknown"),
                              subtitle: isSelected 
                                ? Text("Jersey: #${selectedPlayersWithJersey[pId]}", style: TextStyle(color: primary, fontWeight: FontWeight.bold))
                                : Text("${player['position']} • ${player['nationality']}"),
                              trailing: isSelected ? Icon(Icons.check_circle, color: primary) : const Icon(Icons.add_circle_outline),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: selectedPlayersWithJersey.isEmpty ? null : _confirmPlayers,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Add Selected Players", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          if (_isLoading)
            Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
