import 'package:flutter/material.dart';

class MyLeaguesPage extends StatelessWidget {
  const MyLeaguesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for favorite leagues
    final List<Map<String, String>> favoriteLeagues = [
      // {
      //   "name": "Premier League",
      //   "logo": "asset/leagues_logo/premier_league.png",
      // },
      // {
      //   "name": "La Liga",
      //   "logo": "asset/leagues_logo/la_liga.png",
      // }
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Leagues"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).primaryColor,
      ),
      body: favoriteLeagues.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No favorite leagues yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteLeagues.length,
              itemBuilder: (context, index) {
                final league = favoriteLeagues[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: Image.asset(league['logo']!, errorBuilder: (c, e, s) => const Icon(Icons.sports_soccer)),
                    ),
                    title: Text(league['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Future navigation to league details
                    },
                  ),
                );
              },
            ),
    );
  }
}
