import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/models/invitation_model.dart';
import 'package:uuid/uuid.dart';

class CreatePlayersPage extends StatefulWidget {
  final Team team;
  final String leagueName;
  const CreatePlayersPage({super.key, required this.team, required this.leagueName});

  @override
  State<CreatePlayersPage> createState() => _CreatePlayersPageState();
}

class _CreatePlayersPageState extends State<CreatePlayersPage> {
  final TextEditingController searchController = TextEditingController();
  final leaguesBox = Hive.box<League>('leagues');
  final invitationsBox = Hive.box<Invitation>('invitations');
  
  List<Player> allAvailablePlayers = [];
  List<Player> filteredPlayers = [];
  Map<String, int> selectedPlayersWithJersey = {}; // PlayerID -> JerseyNumber

  @override
  void initState() {
    super.initState();
    _loadAllPlayers();
  }

  void _loadAllPlayers() {
    final List<Player> players = [];
    for (var league in leaguesBox.values) {
      for (var team in league.teams) {
        players.addAll(team.players);
      }
    }
    final ids = <String>{};
    allAvailablePlayers = players.where((p) => ids.add(p.backendId ?? p.name)).toList();
    filteredPlayers = List.from(allAvailablePlayers);
  }

  void _onSearch(String query) {
    setState(() {
      filteredPlayers = allAvailablePlayers
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              (p.backendId?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    });
  }

  void _showJerseyDialog(Player player) {
    final TextEditingController jerseyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Assign Jersey Number for ${player.name}"),
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
                  selectedPlayersWithJersey[player.backendId ?? player.name] = int.parse(jerseyController.text);
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

  void _sendInvitations() {
    for (var entry in selectedPlayersWithJersey.entries) {
      final player = allAvailablePlayers.firstWhere((p) => (p.backendId ?? p.name) == entry.key);
      final invite = Invitation(
        id: const Uuid().v4(),
        teamName: widget.team.name,
        leagueName: widget.leagueName,
        playerName: player.name,
        playerId: player.backendId ?? player.name,
        jerseyNumber: entry.value,
        status: 'pending',
        timestamp: DateTime.now(),
      );
      invitationsBox.add(invite);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Invitations sent to selected players!"), backgroundColor: Colors.green),
    );
    Navigator.pop(context, widget.team); // Return the team (players will be added as they accept)
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Colors.blue[900]!;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Invite Players"),
        backgroundColor: Colors.grey.shade100,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text("${selectedPlayersWithJersey.length} Invited", style: const TextStyle(fontWeight: FontWeight.bold))),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: "Search players to invite...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredPlayers.length,
              itemBuilder: (context, index) {
                final player = filteredPlayers[index];
                final playerKey = player.backendId ?? player.name;
                final isSelected = selectedPlayersWithJersey.containsKey(playerKey);

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: isSelected ? primary : Colors.transparent, width: 2),
                  ),
                  child: ListTile(
                    onTap: () => isSelected ? setState(() => selectedPlayersWithJersey.remove(playerKey)) : _showJerseyDialog(player),
                    leading: CircleAvatar(child: Text(player.name[0])),
                    title: Text(player.name),
                    subtitle: isSelected 
                      ? Text("Jersey: #${selectedPlayersWithJersey[playerKey]}", style: TextStyle(color: primary, fontWeight: FontWeight.bold))
                      : Text(player.position),
                    trailing: isSelected ? Icon(Icons.mail_outline, color: primary) : const Icon(Icons.add_circle_outline),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: selectedPlayersWithJersey.isEmpty ? null : _sendInvitations,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Send Invitations", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
