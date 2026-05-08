import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/pages_details/details_match.dart';
import 'package:offside/pages_details/details_player.dart';
import 'package:offside/services/sync_service.dart';

class LeaguePage extends StatefulWidget {
  final League league;
  const LeaguePage({super.key, required this.league});

  @override
  State<LeaguePage> createState() => _LeaguePageState();
}

class _LeaguePageState extends State<LeaguePage> {
  bool _isLoading = false;

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      await SyncService.fetchAllLeaguesFromBackend();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to refresh: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color headerColor = Color(0xFF0D1956);

    return ValueListenableBuilder(
      valueListenable: Hive.box<League>('leagues').listenable(),
      builder: (context, Box<League> box, _) {
        // Find the most up-to-date league object from the box
        final currentLeague = box.values.firstWhere(
          (l) => (l.backendId != null && l.backendId == widget.league.backendId) || l.name == widget.league.name,
          orElse: () => widget.league,
        );

        // Recalculate dynamic stats
        currentLeague.updateStandings();
        currentLeague.generateTopScorers();
        currentLeague.generateTopAssistants();

        final matchesSorted = List<Match2>.from(currentLeague.matches)
          ..sort((a, b) => a.date.compareTo(b.date));

        final matchesByDate = <String, List<Match2>>{};
        for (var m in matchesSorted) {
          String dateKey = DateFormat('yyyy-MM-dd').format(m.date);
          matchesByDate.putIfAbsent(dateKey, () => []).add(m);
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(240),
              child: Container(
                color: headerColor,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            IconButton(
                              icon: _isLoading 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.refresh, color: Colors.white),
                              onPressed: _isLoading ? null : _refreshData,
                            ),
                          ],
                        ),
                      ),
                      Hero(
                        tag: 'league_logo_${currentLeague.name}',
                        child: Image.asset(currentLeague.logo, height: 60),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentLeague.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const TabBar(
                        indicatorColor: Colors.yellow,
                        labelColor: Colors.yellow,
                        unselectedLabelColor: Colors.white,
                        indicatorWeight: 4,
                        tabs: [
                          Tab(text: "Matches"),
                          Tab(text: "Standings"),
                          Tab(text: "Leaders"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: Container(
              decoration: const BoxDecoration(
                color: headerColor,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: TabBarView(
                  children: [
                    _buildMatchesTab(matchesByDate, theme, context, currentLeague),
                    _buildStandingsTab(theme, currentLeague),
                    _buildPlayersTab(theme, currentLeague),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchesTab(Map<String, List<Match2>> matchesByDate, ThemeData theme, BuildContext context, League league) {
    if (matchesByDate.isEmpty) {
      return const Center(child: Text("No matches scheduled"));
    }
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: matchesByDate.entries.map((entry) {
        final matches = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                DateFormat('EEEE, dd MMM yyyy').format(matches.first.date),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...matches.map((m) {
              final isUpcoming = now.isBefore(m.date);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MatchDetailsPage(match: m, league: league)),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                m.homeTeam.name,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(m.homeTeam.logo, width: 24, height: 24),
                          ],
                        ),
                      ),
                      Container(
                        width: 70,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isUpcoming 
                              ? DateFormat('HH:mm').format(m.date) 
                              : "${m.homeTeamScore} - ${m.awayTeamScore}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: isUpcoming ? 13 : 15,
                            color: isUpcoming ? Colors.grey[700] : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Image.asset(m.awayTeam.logo, width: 24, height: 24),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                m.awayTeam.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStandingsTab(ThemeData theme, League league) {
    final sortedTeams = [...league.teams]..sort((a, b) {
      final pointsA = a.points ?? 0;
      final pointsB = b.points ?? 0;
      if (pointsB != pointsA) return pointsB.compareTo(pointsA);
      final diffA = (a.goalsFor ?? 0) - (a.goalsAgainst ?? 0);
      final diffB = (b.goalsFor ?? 0) - (b.goalsAgainst ?? 0);
      if (diffB != diffA) return diffB.compareTo(diffA);
      final gfA = a.goalsFor ?? 0;
      final gfB = b.goalsFor ?? 0;
      if (gfB != gfA) return gfB.compareTo(gfA);
      return a.name.compareTo(b.name);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 12,
                  headingRowHeight: 45,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 52,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
                  columns: const [
                    DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('TEAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('P', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('L', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('GD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('DIFF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('PTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                  rows: List.generate(sortedTeams.length, (index) {
                    final t = sortedTeams[index];
                    final diff = (t.goalsFor ?? 0) - (t.goalsAgainst ?? 0);
                    final isTop = index < 3;
                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}', style: TextStyle(
                          fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                          color: isTop ? Colors.blue[900] : Colors.black54,
                        ))),
                        DataCell(Row(
                          children: [
                            Image.asset(t.logo, width: 22, height: 22),
                            const SizedBox(width: 8),
                            Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        )),
                        DataCell(Text('${t.played ?? 0}')),
                        DataCell(Text('${t.wins ?? 0}')),
                        DataCell(Text('${t.draw ?? 0}')),
                        DataCell(Text('${t.losses ?? 0}')),
                        DataCell(Text('${t.goalsFor ?? 0}')),
                        DataCell(Text(diff > 0 ? '+$diff' : '$diff', style: TextStyle(
                          color: diff > 0 ? Colors.green : (diff < 0 ? Colors.red : Colors.black),
                          fontWeight: FontWeight.w500,
                        ))),
                        DataCell(Text('${t.points ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D1956)))),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 16,
        children: [
          _legendItem("P: Played", Colors.black54),
          _legendItem("W: Wins", Colors.black54),
          _legendItem("D: Draws", Colors.black54),
          _legendItem("L: Losses", Colors.black54),
          _legendItem("GD: Goals Scored", Colors.black54),
          _legendItem("DIFF: Goal Difference", Colors.black54),
          _legendItem("PTS: Points", Colors.black54),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Text(text, style: TextStyle(fontSize: 10, color: color));
  }

  Widget _buildPlayersTab(ThemeData theme, League league) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: const Color(0xFF0D1956),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: "Top Scorers"),
                Tab(text: "Top Assists"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildLeaderboardList(league.topScorers ?? [], "goals", league),
                _buildLeaderboardList(league.topAssistants ?? [], "assists", league),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<Player> players, String statType, League league) {
    if (players.isEmpty) {
      return const Center(child: Text("No data available yet"));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final statValue = statType == "goals" ? player.goals : player.assists;
        
        final teamCandidates = league.teams.where(
          (t) => t.players.any((p) => p.backendId == player.backendId || p.name == player.name),
        );
        
        final hasTeam = teamCandidates.isNotEmpty;
        final teamName = hasTeam ? teamCandidates.first.name : "Unknown";
        final teamLogo = hasTeam ? teamCandidates.first.logo : "asset/Teams_Logo/1.png";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlayerDetailsPage(player: player)),
            ),
            leading: SizedBox(
              width: 50,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: (player.image != null && player.image!.isNotEmpty) 
                        ? (player.image!.startsWith('http') ? NetworkImage(player.image!) : AssetImage(player.image!) as ImageProvider)
                        : null,
                    child: (player.image == null || player.image!.isEmpty) ? const Icon(Icons.person, color: Colors.grey) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Image.asset(teamLogo, width: 16, height: 16),
                    ),
                  ),
                ],
              ),
            ),
            title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text(teamName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$statValue",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D1956)),
                    ),
                    Text(
                      statType.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                if (index < 3)
                   Icon(
                    Icons.workspace_premium, 
                    color: index == 0 ? Colors.amber : (index == 1 ? Colors.grey[400] : Colors.brown[300]),
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
