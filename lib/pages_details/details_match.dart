import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:offside/models/event_model.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/match_stats_model.dart';
import 'package:offside/models/player_stats_model.dart';
import 'package:offside/pages_details/details_team.dart';
import 'package:offside/pages_details/details_player.dart';

class MatchDetailsPage extends StatefulWidget {
  final Match2 match;
  final League league;

  const MatchDetailsPage({
    super.key,
    required this.match,
    required this.league,
  });

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color darkBlue = Color(0xFF0D1956);

    final now = DateTime.now();
    final isUpcoming = now.isBefore(widget.match.date);
    final isLive = now.isAfter(widget.match.date) &&
        now.isBefore(widget.match.date.add(const Duration(minutes: 105)));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Details"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Timeline"),
            Tab(text: "Team Stats"),
            Tab(text: "Player Stats"),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // ================= HEADER =================
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [darkBlue, Color(0xFF16246E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _teamBox(widget.match.homeTeam, widget.league, context),
                Column(
                  children: [
                    Text(
                      isUpcoming 
                          ? DateFormat('HH:mm').format(widget.match.date)
                          : "${widget.match.homeTeamScore} - ${widget.match.awayTeamScore}",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isUpcoming 
                            ? DateFormat('dd MMM yyyy').format(widget.match.date)
                            : (isLive ? "LIVE" : (widget.match.status ?? "Full Time")),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  ],
                ),
                _teamBox(widget.match.awayTeam, widget.league, context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTimelineTab(isUpcoming),
                _buildTeamStatsTab(),
                _buildPlayerStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(bool isUpcoming) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: isUpcoming 
        ? ListTile(
            leading: const Icon(Icons.calendar_today, color: Color(0xFF0D1956)),
            title: const Text("Kick-off Time"),
            subtitle: Text(DateFormat('EEEE, dd MMMM yyyy - HH:mm').format(widget.match.date)),
          )
        : Column(
            children: [
              if (widget.match.eventsHome.isEmpty && widget.match.eventsAway.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text("No significant events recorded."),
                ),
              ...widget.match.eventsHome.map((e) => _eventTimeline(context, e, true)),
              ...widget.match.eventsAway.map((e) => _eventTimeline(context, e, false)),
            ],
          ),
    );
  }

  Widget _buildTeamStatsTab() {
    final statsBox = Hive.box<MatchStats>('match_stats');
    final homeStats = statsBox.values.where((s) => s.matchId == widget.match.backendId && s.teamId == widget.match.homeTeam.backendId).firstOrNull;
    final awayStats = statsBox.values.where((s) => s.matchId == widget.match.backendId && s.teamId == widget.match.awayTeam.backendId).firstOrNull;

    if (homeStats == null && awayStats == null) {
      return const Center(child: Text("No team statistics available for this match."));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statRow("Possession %", homeStats?.acquisitionAvg ?? 0, awayStats?.acquisitionAvg ?? 0),
        _statRow("Goals", (homeStats?.goalCount ?? 0).toDouble(), (awayStats?.goalCount ?? 0).toDouble()),
        _statRow("Passes", (homeStats?.passesCount ?? 0).toDouble(), (awayStats?.passesCount ?? 0).toDouble()),
        _statRow("Fouls", (homeStats?.foulCount ?? 0).toDouble(), (awayStats?.foulCount ?? 0).toDouble()),
        _statRow("Corners", (homeStats?.cornerCount ?? 0).toDouble(), (awayStats?.cornerCount ?? 0).toDouble()),
      ],
    );
  }

  Widget _statRow(String label, double homeVal, double awayVal) {
    final total = homeVal + awayVal;
    final homePercent = total == 0 ? 0.5 : homeVal / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${homeVal.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey)),
              Text("${awayVal.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: homePercent,
            backgroundColor: Colors.red.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatsTab() {
    final playerStatsBox = Hive.box<PlayerStats>('player_stats');
    final matchPlayerStats = playerStatsBox.values.where((s) => s.matchId == widget.match.backendId).toList();

    if (matchPlayerStats.isEmpty) {
      return const Center(child: Text("No player statistics available for this match."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matchPlayerStats.length,
      itemBuilder: (context, index) {
        final stat = matchPlayerStats[index];
        final player = Hive.box<Player>('players').values.firstWhere((p) => p.backendId == stat.playerId, orElse: () => Player(name: "Unknown", position: "N/A", age: 0, nationality: "", number: 0));
        
        return Card(
          child: ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerDetailsPage(player: player))),
            title: Text(player.name),
            subtitle: Text("Goals: ${stat.goals ?? 0} | Assists: ${stat.assists ?? 0} | Speed: ${stat.topSpeed ?? 0.0} km/h"),
            trailing: (stat.isMvp ?? false) ? const Icon(Icons.star, color: Colors.amber) : null,
          ),
        );
      },
    );
  }

  Widget _teamBox(Team team, League league, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeamDetailsPage(team: team, league: league),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              team.logo,
              width: 56,
              height: 56,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, color: Colors.white, size: 56),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            team.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTimeline(BuildContext context, Event event, bool isHomeTeam) {
    IconData icon;
    Color iconColor;

    switch (event.type) {
      case "Goal":
        icon = Icons.sports_soccer;
        iconColor = Colors.green;
        break;
      case "Yellow Card":
        icon = Icons.square;
        iconColor = Colors.amber;
        break;
      case "Red Card":
        icon = Icons.square;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: isHomeTeam
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(child: Text(event.player, textAlign: TextAlign.end)),
                      const SizedBox(width: 8),
                      Icon(icon, color: iconColor, size: 20),
                    ],
                  )
                : const SizedBox(),
          ),
          Container(width: 40, alignment: Alignment.center, child: Text("${event.minute}'")),
          Expanded(
            child: !isHomeTeam
                ? Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 8),
                      Flexible(child: Text(event.player)),
                    ],
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
