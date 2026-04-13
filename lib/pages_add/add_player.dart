import 'package:flutter/material.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/team_model.dart';

class CreatePlayersPage extends StatefulWidget {
  final Team team;
  const CreatePlayersPage({super.key, required this.team});

  @override
  State<CreatePlayersPage> createState() => _CreatePlayersPageState();
}

class _CreatePlayersPageState extends State<CreatePlayersPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController nationalityController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  String selectedPosition = "Forward";
  List<Player> players = [];

  final List<String> positions = ["Goalkeeper", "Defender", "Midfielder", "Forward"];

  void addPlayer() {
    if (nameController.text.isNotEmpty) {
      setState(() {
        players.add(Player(
          name: nameController.text.trim(),
          position: selectedPosition,
          age: int.tryParse(ageController.text) ?? 20,
          nationality: nationalityController.text.trim().isEmpty ? "Unknown" : nationalityController.text.trim(),
          number: int.tryParse(numberController.text) ?? 0,
          height: double.tryParse(heightController.text) ?? 0.0,
          weight: double.tryParse(weightController.text) ?? 0.0,
        ));
        nameController.clear();
        ageController.clear();
        numberController.clear();
        heightController.clear();
        weightController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: Text("Players for ${widget.team.name}"), backgroundColor: Colors.grey.shade100,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: ageController, decoration: const InputDecoration(labelText: "Age", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: numberController, decoration: const InputDecoration(labelText: "Jersey #", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 10),
            TextField(controller: nationalityController, decoration: const InputDecoration(labelText: "Nationality", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: heightController, decoration: const InputDecoration(labelText: "Height (cm)", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: weightController, decoration: const InputDecoration(labelText: "Weight (kg)", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedPosition,
              items: positions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) => setState(() => selectedPosition = val!),
              decoration: const InputDecoration(labelText: "Position", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: addPlayer,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Player", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
            ),
            const Divider(height: 30),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: players.length,
              itemBuilder: (context, index) => ListTile(
                title: Text("${players[index].name} (#${players[index].number})"),
                subtitle: Text("${players[index].position} | ${players[index].nationality}"),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => players.removeAt(index))),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, Team(
                name: widget.team.name,
                logo: widget.team.logo,
                players: players,
                primaryColor: widget.team.primaryColor,
                secondaryColor: widget.team.secondaryColor,
              )),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green),
              child: const Text("Save & Return", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
