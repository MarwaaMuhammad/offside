import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/services/sync_service.dart';

class PlayerProfilePage extends StatefulWidget {
  final String playerName;

  const PlayerProfilePage({super.key, required this.playerName});

  @override
  State<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage> {
  final playerBox = Hive.box<Player>('players');
  final leaguesBox = Hive.box<League>('leagues');
  final ImagePicker _picker = ImagePicker();
  bool _isSyncing = false;

  Future<void> _refreshData() async {
    setState(() => _isSyncing = true);
    await SyncService.fetchAllLeaguesFromBackend();
    if (mounted) setState(() => _isSyncing = false);
  }

  Future<void> _pickImage(Player player, ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        player.image = image.path;
        player.save();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Player Dashboard"),
        backgroundColor: Colors.grey.shade100,
        actions: [
          if (_isSyncing)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: _refreshData,
            )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: playerBox.listenable(),
        builder: (context, Box<Player> box, _) {
          final players = box.values.where((p) => p.name == widget.playerName).toList();
          
          if (players.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Player profile not found."),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _refreshData, child: const Text("Sync Data")),
                ],
              ),
            );
          }

          final currentPlayer = players.first;
          
          // Find teams and leagues for this player from leaguesBox
          List<Team> joinedTeams = [];
          for (var league in leaguesBox.values) {
            for (var team in league.teams) {
              if (team.players.any((p) => p.name == widget.playerName)) {
                joinedTeams.add(team);
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(currentPlayer),
                const SizedBox(height: 25),
                
                const Text("Performance Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 2.2,
                  children: [
                    _statCard("Total Goals", "${currentPlayer.goals}", Icons.sports_soccer, Colors.green),
                    _statCard("Total Assists", "${currentPlayer.assists}", Icons.assistant, Colors.orange),
                    _statCard("Appearances", "${currentPlayer.appearances}", Icons.event, Colors.blue),
                    _statCard("Top Speed", "${currentPlayer.highestSpeed?.toStringAsFixed(1) ?? '0.0'} km/h", Icons.speed, Colors.red),
                    _statCard("Distance", "${(currentPlayer.totalDistance ?? 0 / 1000).toStringAsFixed(2)} km", Icons.directions_run, Colors.purple),
                    _statCard("Cards", "${currentPlayer.yellowCards}Y / ${currentPlayer.redCards}R", Icons.style, Colors.amber),
                  ],
                ),
                
                const SizedBox(height: 30),
                const Text("Teams & Organizations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (joinedTeams.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Not assigned to any team yet.", style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...joinedTeams.map((team) => Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: Image.asset(team.logo, width: 35),
                      title: Text(team.name),
                      subtitle: Text(team.players.any((p) => p.name == widget.playerName) ? "Active Member" : ""),
                    ),
                  )),
                
                const SizedBox(height: 30),
                // Heatmap Placeholder
                const Text("Recent Performance Heatmap", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage('asset/heatmap_placeholder.png'), // Ensure you have this or use a network image
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black54,
                      child: const Text("Visual Activity Data", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Player player) {
    const Color darkBlue = Color(0xFF16246E);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [darkBlue, Color(0xFF0D1956)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: darkBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white24,
                backgroundImage: player.image != null && player.image!.isNotEmpty && !player.image!.startsWith('asset')
                    ? FileImage(File(player.image!))
                    : (player.image != null && player.image!.startsWith('asset') ? AssetImage(player.image!) : null) as ImageProvider?,
                child: player.image == null || player.image!.isEmpty 
                    ? const Icon(Icons.person, size: 50, color: Colors.white70) 
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showPicker(player),
                  child: const CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.camera_alt, size: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text("${player.position} • Jersey #${player.number}", style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                Text("${player.nationality}", style: const TextStyle(color: Colors.white54, fontSize: 14)),
                Text("${player.height?.toInt() ?? 0}cm | ${player.weight?.toInt() ?? 0}kg", style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(Player player) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { _pickImage(player, ImageSource.gallery); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Camera'), onTap: () { _pickImage(player, ImageSource.camera); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ]
            ),
          ),
        ],
      ),
    );
  }
}
