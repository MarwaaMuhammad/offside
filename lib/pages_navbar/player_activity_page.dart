import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/pages_details/details_match.dart';
import 'package:offside/theme_provider.dart';

class PlayerActivityPage extends StatefulWidget {
  final String playerName;
  const PlayerActivityPage({super.key, required this.playerName});

  @override
  State<PlayerActivityPage> createState() => _PlayerActivityPageState();
}

class _PlayerActivityPageState extends State<PlayerActivityPage>
    with SingleTickerProviderStateMixin {
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

  String _matchStatus(Match2 m) {
    final now = DateTime.now();
    if (now.isBefore(m.date)) return 'upcoming';
    if (now.isBefore(m.date.add(const Duration(minutes: 105)))) return 'live';
    return 'finished';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPri = isDark ? AppColors.darkTextPri : AppColors.lightTextPri;
    final textSec = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return ValueListenableBuilder<Box<League>>(
      valueListenable: Hive.box<League>('leagues').listenable(),
      builder: (context, box, _) {
        // Find all leagues + teams + matches this player is in
        final List<_LeagueEntry> entries = [];

        for (final league in box.values) {
          for (final team in league.teams) {
            final inTeam =
                team.players.any((p) => p.name == widget.playerName);
            if (inTeam) {
              final matches = league.matches
                  .where((m) =>
                      m.homeTeam.name == team.name ||
                      m.awayTeam.name == team.name)
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date));
              entries.add(_LeagueEntry(
                league: league,
                team: team,
                matches: matches,
              ));
            }
          }
        }

        return Scaffold(
          backgroundColor: bg,
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                backgroundColor: bg,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      size: 18, color: textPri),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'My Activity',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPri,
                  ),
                ),
                centerTitle: true,
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: primary,
                  indicatorWeight: 3,
                  labelColor: primary,
                  unselectedLabelColor: textSec,
                  labelStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle:
                      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'Leagues'),
                    Tab(text: 'Teams'),
                    Tab(text: 'Matches'),
                  ],
                ),
              ),
            ],
            body: entries.isEmpty
                ? _emptyState(textSec)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _LeaguesTab(
                          entries: entries,
                          isDark: isDark,
                          primary: primary,
                          cardBg: cardBg,
                          textPri: textPri,
                          textSec: textSec,
                          divider: divider),
                      _TeamsTab(
                          entries: entries,
                          isDark: isDark,
                          primary: primary,
                          cardBg: cardBg,
                          textPri: textPri,
                          textSec: textSec,
                          divider: divider),
                      _MatchesTab(
                          entries: entries,
                          isDark: isDark,
                          primary: primary,
                          cardBg: cardBg,
                          textPri: textPri,
                          textSec: textSec,
                          divider: divider,
                          matchStatus: _matchStatus,
                          context: context),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _emptyState(Color textSec) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer_outlined,
              size: 72, color: textSec.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No activity yet',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textSec),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t been added to any\nleague or team yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: textSec),
          ),
        ],
      ),
    );
  }
}

// ── Data class ─────────────────────────────────────────────────────────
class _LeagueEntry {
  final League league;
  final Team team;
  final List<Match2> matches;
  _LeagueEntry(
      {required this.league, required this.team, required this.matches});
}

// ── Leagues Tab ─────────────────────────────────────────────────────────
class _LeaguesTab extends StatelessWidget {
  final List<_LeagueEntry> entries;
  final bool isDark;
  final Color primary, cardBg, textPri, textSec, divider;

  const _LeaguesTab({
    required this.entries,
    required this.isDark,
    required this.primary,
    required this.cardBg,
    required this.textPri,
    required this.textSec,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    // De-duplicate leagues
    final seen = <String>{};
    final unique = entries.where((e) => seen.add(e.league.name)).toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: unique.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final e = unique[i];
        final l = e.league;
        final upcoming = l.matches
            .where((m) => m.date.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final nextMatch = upcoming.isNotEmpty ? upcoming.first : null;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(l.logo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.emoji_events,
                                color: primary,
                                size: 28)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.name,
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textPri)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _statusChip(l, primary, textSec),
                              const SizedBox(width: 8),
                              if (l.startDate != null)
                                Text(
                                  DateFormat('MMM yyyy').format(l.startDate!),
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: textSec),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Team chip
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.group_outlined, size: 14, color: textSec),
                    const SizedBox(width: 6),
                    Text('Playing for: ',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: textSec)),
                    Text(e.team.name,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primary)),
                  ],
                ),
              ),
              // Next match
              if (nextMatch != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Divider(color: divider, height: 1),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: textSec),
                      const SizedBox(width: 6),
                      Text('Next: ',
                          style:
                              GoogleFonts.inter(fontSize: 12, color: textSec)),
                      Text(
                        '${nextMatch.homeTeam.name} vs ${nextMatch.awayTeam.name}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textPri),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(nextMatch.date),
                        style:
                            GoogleFonts.inter(fontSize: 11, color: textSec),
                      ),
                    ],
                  ),
                ),
              ] else
                const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(League l, Color primary, Color textSec) {
    final now = DateTime.now();
    String label;
    Color color;
    if (l.endDate != null && now.isAfter(l.endDate!)) {
      label = 'Finished';
      color = textSec;
    } else if (l.startDate != null && now.isBefore(l.startDate!)) {
      label = 'Upcoming';
      color = AppColors.darkAccent;
    } else {
      label = 'Active';
      color = primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Teams Tab ─────────────────────────────────────────────────────────
class _TeamsTab extends StatelessWidget {
  final List<_LeagueEntry> entries;
  final bool isDark;
  final Color primary, cardBg, textPri, textSec, divider;

  const _TeamsTab({
    required this.entries,
    required this.isDark,
    required this.primary,
    required this.cardBg,
    required this.textPri,
    required this.textSec,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final team = entries[i].team;
        final league = entries[i].league;
        final players = team.players;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(team.logo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.shield_outlined,
                                color: primary,
                                size: 30)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(team.name,
                              style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: textPri)),
                          const SizedBox(height: 4),
                          Text('in ${league.name}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: textSec)),
                        ],
                      ),
                    ),
                    // Points badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text('${team.points ?? 0}',
                              style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: primary)),
                          Text('pts',
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: textSec)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Stats row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Divider(color: divider, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCol('${team.played ?? 0}', 'Played', textPri, textSec),
                    _dividerV(divider),
                    _statCol('${team.wins ?? 0}', 'W', primary, textSec),
                    _dividerV(divider),
                    _statCol('${team.draw ?? 0}', 'D', textSec, textSec),
                    _dividerV(divider),
                    _statCol('${team.losses ?? 0}', 'L',
                        AppColors.darkError, textSec),
                    _dividerV(divider),
                    _statCol('${players.length}', 'Players', textPri, textSec),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCol(String val, String lbl, Color valColor, Color lblColor) {
    return Column(
      children: [
        Text(val,
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: valColor)),
        Text(lbl,
            style: GoogleFonts.inter(fontSize: 10, color: lblColor)),
      ],
    );
  }

  Widget _dividerV(Color color) =>
      Container(width: 1, height: 28, color: color);
}

// ── Matches Tab ─────────────────────────────────────────────────────────
class _MatchesTab extends StatelessWidget {
  final List<_LeagueEntry> entries;
  final bool isDark;
  final Color primary, cardBg, textPri, textSec, divider;
  final String Function(Match2) matchStatus;
  final BuildContext context;

  const _MatchesTab({
    required this.entries,
    required this.isDark,
    required this.primary,
    required this.cardBg,
    required this.textPri,
    required this.textSec,
    required this.divider,
    required this.matchStatus,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    // Collect all matches with their league, deduplicate by backendId or date+teams
    final seen = <String>{};
    final all = <({Match2 match, League league})>[];
    for (final e in entries) {
      for (final m in e.matches) {
        final key = '${m.date}|${m.homeTeam.name}|${m.awayTeam.name}';
        if (seen.add(key)) {
          all.add((match: m, league: e.league));
        }
      }
    }
    all.sort((a, b) => a.match.date.compareTo(b.match.date));

    if (all.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 64, color: textSec.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No matches scheduled',
                style: GoogleFonts.inter(fontSize: 15, color: textSec)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: all.length,
      itemBuilder: (_, i) {
        final item = all[i];
        return _buildMatchCard(ctx, item.match, item.league);
      },
    );
  }

  Widget _buildMatchCard(BuildContext ctx, Match2 m, League league) {
    final status = matchStatus(m);
    final isLive = status == 'live';
    final isUpcoming = status == 'upcoming';

    final statusColor = isLive
        ? AppColors.darkPrimary
        : isUpcoming
            ? AppColors.darkAccent
            : textSec;
    final statusLabel = isLive ? 'LIVE' : isUpcoming ? 'UPCOMING' : 'FT';

    return GestureDetector(
      onTap: () => Navigator.push(
        ctx,
        MaterialPageRoute(
            builder: (_) => MatchDetailsPage(match: m, league: league)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive
                ? primary.withValues(alpha: 0.5)
                : divider,
          ),
          boxShadow: isLive
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // League + status row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(league.logo,
                        width: 16,
                        height: 16,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: textSec)),
                  ),
                  const SizedBox(width: 6),
                  Text(league.name,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textSec)),
                  const Spacer(),
                  if (isLive) ...[
                    _liveDot(),
                    const SizedBox(width: 4),
                  ],
                  Text(statusLabel,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                  if (!isLive) ...[
                    const SizedBox(width: 4),
                    Text('• ${DateFormat('HH:mm').format(m.date)}',
                        style:
                            GoogleFonts.inter(fontSize: 10, color: textSec)),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Teams + score row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Image.asset(m.homeTeam.logo,
                            width: 36,
                            height: 36,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.shield, size: 36)),
                        const SizedBox(height: 4),
                        Text(m.homeTeam.name,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPri),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  // Centre: score or date
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: isUpcoming
                          ? Column(
                              children: [
                                Text(
                                  DateFormat('dd MMM').format(m.date),
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: textSec),
                                ),
                                Text(
                                  DateFormat('HH:mm').format(m.date),
                                  style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: textPri),
                                ),
                              ],
                            )
                          : Text(
                              '${m.homeTeamScore}  –  ${m.awayTeamScore}',
                              style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isLive ? primary : textPri),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(m.awayTeam.logo,
                            width: 36,
                            height: 36,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.shield, size: 36)),
                        const SizedBox(height: 4),
                        Text(m.awayTeam.name,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPri),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _liveDot() => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkPrimary,
          boxShadow: [
            BoxShadow(
                color: AppColors.darkPrimary.withValues(alpha: 0.7),
                blurRadius: 6,
                spreadRadius: 1)
          ],
        ),
      );
}
