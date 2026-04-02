import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:intl/intl.dart';
import 'package:offside/pages_details/details_league.dart';
// ── NEW ──────────────────────────────────────────────────────────────
import 'package:offside/services/sync_service.dart';
import 'package:offside/services/api_service.dart';
// ─────────────────────────────────────────────────────────────────────

class CreateMatchPage extends StatefulWidget {
  final List<Team> teams;
  final String leagueLogo;
  final String leagueName;

  const CreateMatchPage({
    super.key,
    required this.teams,
    required this.leagueLogo,
    required this.leagueName,
  });

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  List<Match2> matches = [];
  bool _isSyncing = false; // shows loading indicator during backend sync

  void createMatch() {
    setState(() {
      matches.clear();
      final shuffledTeams = List<Team>.from(widget.teams)..shuffle();

      for (int i = 0; i < shuffledTeams.length; i++) {
        for (int j = i + 1; j < shuffledTeams.length; j++) {
          matches.add(Match2(
            homeTeam: shuffledTeams[i],
            awayTeam: shuffledTeams[j],
            date: DateTime.now(),
          ));
        }
      }
    });
  }

  Future<void> pickDateTime(int index) async {
    // Pick date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: matches[index].date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    // Pick time
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(matches[index].date),
    );
    if (pickedTime == null) return;

    // Merge date with time
    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      matches[index] = Match2(
        homeTeam: matches[index].homeTeam,
        awayTeam: matches[index].awayTeam,
        date: newDateTime,
      );
    });
  }

  // ── UPDATED saveMatches: saves locally THEN syncs to backend ──────
  Future<void> saveMatches() async {
    setState(() => _isSyncing = true);

    try {
      // 1. Save locally to Hive first (always works offline)
      final leagueBox = await Hive.openBox<League>('leagues');
      final league = League(
        logo: widget.leagueLogo,
        name: widget.leagueName,
        teams: widget.teams,
        matches: matches,
      );
      await leagueBox.add(league);
      await leagueBox.flush(); // Ensure immediate save

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ League '${widget.leagueName}' saved locally!")),
      );

      // 2. Now sync to backend
      await SyncService.syncLeagueToBackend(league);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("☁️  League synced to backend!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LeaguePage(league: league)),
      );
    } on ApiException catch (e) {
      // Backend failed but local save succeeded — still navigate
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️  Saved locally but backend sync failed: ${e.message}"),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );

      final leagueBox = Hive.box<League>('leagues');
      final league = leagueBox.values.last;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LeaguePage(league: league)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd – HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text("Create Matches - ${widget.leagueName}"),
        actions: [
          _isSyncing
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save, color: Colors.black),
                  onPressed: matches.isEmpty ? null : saveMatches,
                ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: matches.isEmpty
                ? const Center(
                    child: Text("⚽ No matches yet. Click below to create."),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 4,
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    AssetImage(match.homeTeam.logo),
                                radius: 18,
                              ),
                              const SizedBox(width: 5),
                              CircleAvatar(
                                backgroundImage:
                                    AssetImage(match.awayTeam.logo),
                                radius: 18,
                              ),
                            ],
                          ),
                          title: Text(
                            "${match.homeTeam.name} 🆚 ${match.awayTeam.name}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "📅 ${dateFormat.format(match.date)}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_calendar,
                                color: Colors.blueAccent),
                            onPressed: () => pickDateTime(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: createMatch,
              icon: const Icon(Icons.add),
              label: const Text("Create Matches"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
