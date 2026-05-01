import 'package:flutter/material.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/pages_details/details_match.dart';
import 'package:offside/pages_details/details_player.dart';
import 'package:intl/intl.dart';

class TeamDetailsPage extends StatefulWidget {
  final Team team;
  final League league;

  const TeamDetailsPage({super.key, required this.team, required this.league});

  @override
  State<TeamDetailsPage> createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends State<TeamDetailsPage>
    with SingleTickerProviderStateMixin {
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color headerColor = Color(0xFF0D1956);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(250),
          child: Container(
            color: headerColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  tag: 'team_logo_${widget.team.name}',
                  child: Image.asset(widget.team.logo, height: 70),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.team.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const TabBar(
                  indicatorColor: Colors.yellow,
                  labelColor: Colors.yellow,
                  unselectedLabelColor: Colors.white,
                  indicatorWeight: 4,
                  tabs: [
                    Tab(text: "Matches"),
                    Tab(text: "Standings"),
                    Tab(text: "Squad"),
                  ],
                ),
              ],
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
                _buildMatchesTab(),
                _buildStandingsTab(),
                _buildSquadTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesTab() {
    final now = DateTime.now();
    final teamMatches = widget.league.matches.where((m) {
      return m.homeTeam.name == widget.team.name ||
             m.awayTeam.name == widget.team.name;
    }).toList();

    if (teamMatches.isEmpty) {
      return const Center(child: Text("No matches found"));
    }

    final matchesByDate = <String, List<dynamic>>{};
    for (var m in teamMatches) {
      String dateKey = DateFormat('yyyy-MM-dd').format(m.date);
      matchesByDate.putIfAbsent(dateKey, () => []).add(m);
    }

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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...matches.map((m) {
              final isUpcoming = now.isBefore(m.date);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MatchDetailsPage(match: m, league: widget.league)),
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
                                style: const TextStyle(fontSize: 14),
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

  Widget _buildStandingsTab() {
    widget.league.updateStandings();
    final sortedTeams = [...widget.league.teams]..sort((a, b) {
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
            final isCurrentTeam = t.name == widget.team.name;
            return DataRow(
              color: isCurrentTeam ? WidgetStateProperty.all(Colors.white.withOpacity(0.1)) : null,
              cells: [
                DataCell(Text('${index + 1}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                DataCell(Row(
                  children: [
                    Image.asset(t.logo, width: 20, height: 20),
                    const SizedBox(width: 8),
                    Text(t.name, style: TextStyle(fontWeight: isCurrentTeam ? FontWeight.bold : FontWeight.normal)),
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

  Widget _buildSquadTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.team.players.length,
      itemBuilder: (context, index) {
        final player = widget.team.players[index];
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
            subtitle: Text(player.position),
            trailing: Text(
              "#${player.number}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1956),
              ),
            ),
          ),
        );
      },
    );
  }
}
