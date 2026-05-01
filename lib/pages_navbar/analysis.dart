import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/pages_details/details_league.dart';
import 'package:offside/pages_details/details_team.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final leaguesBox = Hive.box<League>('leagues');
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ============================
            // SEARCH BAR
            // ============================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search teams or leagues...",
                    hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                    icon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.4)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ============================
            // RESULTS LIST (REACTIVE)
            // ============================
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: leaguesBox.listenable(),
                builder: (context, Box<League> box, _) {
                  final allLeagues = box.values.toList();
                  
                  // Filter Leagues
                  final filteredLeagues = searchQuery.isEmpty 
                      ? allLeagues 
                      : allLeagues.where((l) => l.name.toLowerCase().contains(searchQuery)).toList();

                  // Extract and Filter Teams
                  List<Team> allTeams = [];
                  for (var l in allLeagues) {
                    allTeams.addAll(l.teams);
                  }
                  
                  // Only show teams if searching, otherwise it might be too many
                  final filteredTeams = searchQuery.isEmpty 
                      ? [] 
                      : allTeams.where((t) => t.name.toLowerCase().contains(searchQuery)).toList();

                  if (filteredLeagues.isEmpty && filteredTeams.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: colorScheme.outline.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            "No results found",
                            style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.outline),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (filteredLeagues.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text("LEAGUES", style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.2, color: colorScheme.primary)),
                        ),
                        ...filteredLeagues.map((l) => leagueTile(l, theme)),
                        const SizedBox(height: 16),
                      ],
                      if (filteredTeams.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text("TEAMS", style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.2, color: colorScheme.primary)),
                        ),
                        ...filteredTeams.map((t) {
                          // Find parent league for team details page
                          final parentLeague = allLeagues.firstWhere((l) => l.teams.contains(t), orElse: () => allLeagues.first);
                          return teamTile(t, parentLeague, theme);
                        }),
                      ],
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget leagueTile(League league, ThemeData theme) {
    const Color cardColor = Color(0xFF0D1956);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LeaguePage(league: league)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'league_logo_${league.name}_${league.backendId}',
              child: Image.asset(league.logo, width: 40, height: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                league.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget teamTile(Team team, League league, ThemeData theme) {
    const Color cardColor = Color(0xFF16246E); 
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamDetailsPage(team: team, league: league),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'team_logo_${team.name}_${team.backendId}',
              child: Image.asset(team.logo, width: 36, height: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Team • ${league.name}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
