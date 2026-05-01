import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/pages_add/add_matches.dart';
import 'package:offside/pages_add/add_player.dart';

class CreateTeamPage extends StatefulWidget {
  final String leagueName;
  final String logo;
  final DateTime? startDate;
  final DateTime? endDate;

  const CreateTeamPage({
    super.key,
    required this.leagueName,
    required this.logo,
    this.startDate,
    this.endDate,
  });

  @override
  State<CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  final TextEditingController teamNameController = TextEditingController();
  
  Color primaryColor = Colors.blue[900]!;
  Color secondaryColor = Colors.white;
  Color goalkeeperColor = Colors.yellow;

  List<Team> teams = [];
  int? selectedLogo;

  final List<String> teamLogos = List.generate(20, (index) => "asset/Teams_Logo/${index + 1}.png");

  String colorToHex(Color color) {
    // Using toARGB32() to avoid deprecation warning and getting the hex string
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  Future<void> _pickColor(BuildContext context, String title, Color initialColor, Function(Color) onColorChanged) async {
    Color selectedColor = initialColor;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Pick $title"),
        content: SingleChildScrollView(
          child: HueRingPicker(
            pickerColor: initialColor,
            onColorChanged: (color) {
              selectedColor = color;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Done"),
          ),
        ],
      ),
    );
    onColorChanged(selectedColor);
  }

  void addTeam() {
    String teamName = teamNameController.text.trim();
    String? teamLogo = selectedLogo != null ? teamLogos[selectedLogo!] : null;

    if (teamName.isNotEmpty && teamLogo != null) {
      setState(() {
        teams.add(Team(
          name: teamName,
          logo: teamLogo,
          players: [],
          primaryColor: colorToHex(primaryColor),
          secondaryColor: colorToHex(secondaryColor),
          goalkeeperColor: colorToHex(goalkeeperColor),
        ));
      });
      
      teamNameController.clear();
      primaryColor = Colors.blue[900]!;
      secondaryColor = Colors.white;
      goalkeeperColor = Colors.yellow;
      setState(() => selectedLogo = null);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Team added! Now add players below."), duration: Duration(seconds: 2)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Name and logo required")));
    }
  }

  void _managePlayers(int index) async {
    final updatedTeam = await Navigator.push<Team>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePlayersPage(
          team: teams[index],
          leagueName: widget.leagueName,
        ),
      ),
    );

    if (updatedTeam != null) {
      setState(() {
        teams[index] = updatedTeam;
      });
    }
  }

  void saveTeams() {
    if (teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Please add at least one team")));
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMatchPage(
          leagueLogo: widget.logo,
          leagueName: widget.leagueName,
          teams: teams,
          startDate: widget.startDate,
          endDate: widget.endDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: Text("Add Teams to ${widget.leagueName}"), backgroundColor: Colors.grey.shade100,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: teamNameController, decoration: const InputDecoration(labelText: "Team Name", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            
            const Text("T-Shirt Colors", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _colorPickerButton("Primary", primaryColor, (color) => setState(() => primaryColor = color)),
                _colorPickerButton("Secondary", secondaryColor, (color) => setState(() => secondaryColor = color)),
                _colorPickerButton("Goalkeeper", goalkeeperColor, (color) => setState(() => goalkeeperColor = color)),
              ],
            ),
            
            const SizedBox(height: 20),
            const Text("Select Team Logo", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(teamLogos.length, (index) {
                return GestureDetector(
                  onTap: () => setState(() => selectedLogo = index),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedLogo == index ? Colors.blue : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[200],
                      child: Padding(padding: const EdgeInsets.all(4), child: Image.asset(teamLogos[index])),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addTeam,
                icon: const Icon(Icons.group_add, color: Colors.white),
                label: const Text("Create Team", style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const Divider(height: 40),
            const Text("Teams in this League:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: teams.length,
              itemBuilder: (context, index) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ListTile(
                      leading: Image.asset(teams[index].logo, width: 40),
                      title: Text(teams[index].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Wrap(
                        spacing: 8,
                        children: [
                          _colorIndicator(teams[index].primaryColor),
                          _colorIndicator(teams[index].secondaryColor),
                          _colorIndicator(teams[index].goalkeeperColor),
                          Text("${teams[index].players.length} Players"),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => teams.removeAt(index)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _managePlayers(index),
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text("Add Players"),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveTeams,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text("Finalize & Create Matches", style: TextStyle(color: Colors.white, fontSize: 18)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorIndicator(String? hexColor) {
    if (hexColor == null) return const SizedBox.shrink();
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Color(int.parse(hexColor.replaceAll('#', '0xFF'))),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
    );
  }

  Widget _colorPickerButton(String label, Color color, Function(Color) onPicked) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickColor(context, label, color, onPicked),
          child: CircleAvatar(
            backgroundColor: color,
            radius: 20,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
