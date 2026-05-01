import 'package:flutter/material.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/pages_details/details_match.dart';
import 'package:offside/pages_details/details_player.dart';
import '../models/leage_model.dart';
import 'package:intl/intl.dart';

class LeaguePage extends StatelessWidget {
  final League league;
  const LeaguePage({super.key, required this.league});

  @override
  Widget build(BuildContext context) {
    league.generateTopScorers();
    league.generateTopAssistants();

    final matchesSorted = List<Match2>.from(league.matches)..sort((a, b) => a.date.compareTo(b.date));

    final matchesByDate = <String, List<Match2>>{};
    for (var m in matchesSorted) {
      String dateKey = DateFormat('yyyy-MM-dd').format(m.date);
      matchesByDate.putIfAbsent(dateKey, () => []).add(m);
    }

    final theme = Theme.of(context);
    const Color headerColor = Color(0xFF0D1956);

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
                        const Icon(Icons.star_border, color: Colors.white),
                      ],
                    ),
                  ),
                  Hero(
                    tag: 'league_logo_${league.name}',
                    child: Image.asset(league.logo, height: 60),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    league.name.toUpperCase(),
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
                      Tab(text: "Teams"),
                      Tab(text: "Players"),
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
                _buildMatchesTab(matchesByDate, theme, context),
                _buildStandingsTab(theme),
                _buildPlayersTab(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesTab(Map<String, List<Match2>> matchesByDate, ThemeData theme, BuildContext context) {
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
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MatchDetailsPage(match: m, league: league)),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Home Team Name + Logo
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                m.homeTeam.name,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(m.homeTeam.logo, width: 24, height: 24),
                          ],
                        ),
                      ),
                      // Score or Time
                      Container(
                        width: 70,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          isUpcoming 
                              ? DateFormat('HH:mm').format(m.date) 
                              : "${m.homeTeamScore} - ${m.awayTeamScore}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: isUpcoming ? 14 : 16,
                            color: isUpcoming ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                      ),
                      // Away Team Logo + Name
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Image.asset(m.awayTeam.logo, width: 24, height: 24),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                m.awayTeam.name,
                                style: const TextStyle(fontSize: 14),
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

  Widget _buildStandingsTab(ThemeData theme) {
    league.updateStandings();
    final sortedTeams = [...league.teams]..sort((a, b) {
      final pointsA = a.points ?? 0;
      final pointsB = b.points ?? 0;
      if (pointsB != pointsA) return pointsB.compareTo(pointsA);
      final diffA = (a.goalsFor ?? 0) - (a.goalsAgainst ?? 0);
      final diffB = (b.goalsFor ?? 0) - (b.goalsAgainst ?? 0);
      if (diffB != diffA) return diffB.compareTo(diffA);
      return a.name.compareTo(b.name);
    });

    const Color tableBg = Color(0xFF0D1956);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tableBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 15,
          headingRowHeight: 40,
          dataRowHeight: 48,
          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Team')),
            DataColumn(label: Text('P')),
            DataColumn(label: Text('W')),
            DataColumn(label: Text('D')),
            DataColumn(label: Text('L')),
            DataColumn(label: Text('Goals')),
            DataColumn(label: Text('Diff')),
            DataColumn(label: Text('Pts')),
          ],
          rows: List.generate(sortedTeams.length, (index) {
            final t = sortedTeams[index];
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                DataCell(Row(
                  children: [
                    Image.asset(t.logo, width: 20, height: 20),
                    const SizedBox(width: 8),
                    Text(t.name),
                  ],
                )),
                DataCell(Text('${t.played ?? 0}')),
                DataCell(Text('${t.wins ?? 0}')),
                DataCell(Text('${t.draw ?? 0}')),
                DataCell(Text('${t.losses ?? 0}')),
                DataCell(Text('${t.goalsFor ?? 0}:${t.goalsAgainst ?? 0}')),
                DataCell(Text('${(t.goalsFor ?? 0) - (t.goalsAgainst ?? 0)}')),
                DataCell(Text('${t.points ?? 0}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPlayersTab(ThemeData theme) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: const Color(0xFF0D1956),
                borderRadius: BorderRadius.circular(30),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
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
                _buildPlayerStatList(league.topScorers ?? [], "goals"),
                _buildPlayerStatList(league.topAssistants ?? [], "assists"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatList(List players, String statType) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final statValue = statType == "goals" ? player.goals : player.assists;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlayerDetailsPage(player: player)),
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0D1956),
              backgroundImage: player.image != null ? AssetImage(player.image!) : null,
              child: player.image == null ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Jersey #${player.number}"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$statValue $statType",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
              ),
            ),
          ),
        );
      },
    );
  }
}
