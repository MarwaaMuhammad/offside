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
      return (m.homeTeam.backendId != null && m.homeTeam.backendId == widget.team.backendId) ||
             (m.awayTeam.backendId != null && m.awayTeam.backendId == widget.team.backendId) ||
             m.homeTeam.name == widget.team.name ||
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildStandingsTab() {
    widget.league.updateStandings();
    final sortedTeams = [...widget.league.teams]..sort((a, b) {
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              headingRowHeight: 45,
              dataRowHeight: 52,
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
                final isCurrentTeam = (t.backendId != null && t.backendId == widget.team.backendId) || t.name == widget.team.name;
                final diff = (t.goalsFor ?? 0) - (t.goalsAgainst ?? 0);
                
                return DataRow(
                  color: isCurrentTeam ? WidgetStateProperty.all(Colors.blue.withOpacity(0.05)) : null,
                  cells: [
                    DataCell(Text('${index + 1}', style: TextStyle(
                      fontWeight: isCurrentTeam ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentTeam ? const Color(0xFF0D1956) : Colors.black54,
                    ))),
                    DataCell(Row(
                      children: [
                        Image.asset(t.logo, width: 22, height: 22),
                        const SizedBox(width: 8),
                        Text(t.name, style: TextStyle(
                          fontWeight: isCurrentTeam ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        )),
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
    );
  }

  Widget _buildSquadTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.team.players.length,
      itemBuilder: (context, index) {
        final player = widget.team.players[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlayerDetailsPage(player: player)),
            ),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF0D1956).withOpacity(0.1),
              backgroundImage: (player.image != null && player.image!.isNotEmpty) 
                  ? (player.image!.startsWith('http') ? NetworkImage(player.image!) : AssetImage(player.image!) as ImageProvider)
                  : null,
              child: (player.image == null || player.image!.isEmpty) ? const Icon(Icons.person, color: Color(0xFF0D1956)) : null,
            ),
            title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text(player.position, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1956).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "#${player.number}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1956),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
