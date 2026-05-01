import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:offside/models/event_model.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/pages_details/details_team.dart';

class MatchDetailsPage extends StatelessWidget {
  final Match2 match;
  final League league;

  const MatchDetailsPage({
    super.key,
    required this.match,
    required this.league,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const Color darkBlue = Color(0xFF0D1956);

    final now = DateTime.now();
    final isUpcoming = now.isBefore(match.date);
    final isLive = now.isAfter(match.date) &&
        now.isBefore(match.date.add(const Duration(minutes: 105)));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Match Details"),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        child: Column(
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _teamBox(match.homeTeam, league, context),
                  Column(
                    children: [
                      Text(
                        isUpcoming 
                            ? DateFormat('HH:mm').format(match.date)
                            : "${match.homeTeamScore} - ${match.awayTeamScore}",
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
                              ? DateFormat('dd MMM yyyy').format(match.date)
                              : (isLive ? "LIVE" : (match.status ?? "Full Time")),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    ],
                  ),
                  _teamBox(match.awayTeam, league, context),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ================= TITLE =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isUpcoming ? "Match Information" : "Match Timeline",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ================= EVENTS TIMELINE / INFO =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              ),
              child: isUpcoming 
                ? ListTile(
                    leading: const Icon(Icons.calendar_today, color: darkBlue),
                    title: const Text("Kick-off Time"),
                    subtitle: Text(DateFormat('EEEE, dd MMMM yyyy - HH:mm').format(match.date)),
                  )
                : Column(
                    children: [
                      if (match.eventsHome.isEmpty && match.eventsAway.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text("No significant events recorded."),
                        ),
                      ...match.eventsHome.map((e) => _eventTimeline(context, e, true)),
                      ...match.eventsAway.map((e) => _eventTimeline(context, e, false)),
                    ],
                  ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
      case "Substitution":
        icon = Icons.swap_vert;
        iconColor = Colors.orange;
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
                      Flexible(
                        child: Text(
                          event.player,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(icon, color: iconColor, size: 20),
                    ],
                  )
                : const SizedBox(),
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              "${event.minute}'",
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: !isHomeTeam
                ? Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          event.player,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
