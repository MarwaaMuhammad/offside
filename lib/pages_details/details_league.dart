import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/pages_details/details_match.dart';
import 'package:offside/pages_details/details_player.dart';
import 'package:offside/services/sync_service.dart';
import 'package:offside/theme_provider.dart';

class LeaguePage extends StatefulWidget {
  final League league;
  const LeaguePage({super.key, required this.league});

  @override
  State<LeaguePage> createState() => _LeaguePageState();
}

class _LeaguePageState extends State<LeaguePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      await SyncService.fetchAllLeaguesFromBackend();
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPri = isDark ? AppColors.darkTextPri : AppColors.lightTextPri;
    final textSec = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    const darkBlueBg = Color(0xFF001F24); // Neon blue tinted dark background

    return ValueListenableBuilder(
      valueListenable: Hive.box<League>('leagues').listenable(),
      builder: (_, Box<League> box, __) {
        final league = box.values.firstWhere(
          (l) =>
              (l.backendId != null &&
                  l.backendId == widget.league.backendId) ||
              l.name == widget.league.name,
          orElse: () => widget.league,
        );
        league.updateStandings();
        league.generateTopScorers();
        league.generateTopAssistants();

        final sorted = List<Match2>.from(league.matches)
          ..sort((a, b) => a.date.compareTo(b.date));
        final byDate = <String, List<Match2>>{};
        for (var m in sorted) {
          byDate.putIfAbsent(
              DateFormat('yyyy-MM-dd').format(m.date), () => []).add(m);
        }

        return Scaffold(
          backgroundColor: bg,
          body: NestedScrollView(
            headerSliverBuilder: (ctx, inner) => [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: isDark ? darkBlueBg : primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _refresh,
                        ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                darkBlueBg,
                                AppColors.darkBg,
                              ]
                            : [primary, primary.withValues(alpha: 0.7)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Hero(
                          tag:
                              'league_logo_${league.name}_${league.backendId}',
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(league.logo,
                                width: 64, height: 64),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          league.name.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (league.startDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('dd MMM').format(league.startDate!)} → '
                            '${DateFormat('dd MMM yyyy').format(league.endDate!)}',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ],
                    ),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                  labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                  tabs: const [
                    Tab(text: 'Matches'),
                    Tab(text: 'Standings'),
                    Tab(text: 'Leaders'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _matchesTab(byDate, league, isDark, primary, cardBg,
                    textPri, textSec, divider),
                _standingsTab(league, isDark, primary, cardBg, textPri,
                    textSec, divider),
                _leadersTab(league, isDark, primary, cardBg, textPri,
                    textSec, divider),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Matches Tab ──────────────────────────────────────
  Widget _matchesTab(
    Map<String, List<Match2>> byDate,
    League league,
    bool isDark,
    Color primary,
    Color cardBg,
    Color textPri,
    Color textSec,
    Color divider,
  ) {
    if (byDate.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 64, color: textSec.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No matches scheduled',
                style: GoogleFonts.inter(fontSize: 14, color: textSec)),
          ],
        ),
      );
    }
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: byDate.entries.map((entry) {
        final matches = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    DateFormat('EEEE, dd MMM').format(matches.first.date),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primary,
                        letterSpacing: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(
                        color: primary.withValues(alpha: 0.3), thickness: 1),
                  ),
                ],
              ),
            ),
            ...matches.map((m) {
              final isUpcoming = now.isBefore(m.date);
              final isLive = now.isAfter(m.date) &&
                  now.isBefore(
                      m.date.add(const Duration(minutes: 105)));
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          MatchDetailsPage(match: m, league: league)),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isLive
                          ? primary.withValues(alpha: 0.4)
                          : divider,
                    ),
                    boxShadow: isLive
                        ? [
                            BoxShadow(
                                color: primary.withValues(alpha: 0.12),
                                blurRadius: 10)
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(m.homeTeam.name,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textPri),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(m.homeTeam.logo,
                                width: 28, height: 28),
                          ],
                        ),
                      ),
                      Container(
                        width: 72,
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            if (isLive) _liveDot(primary),
                            Text(
                              isUpcoming
                                  ? DateFormat('HH:mm').format(m.date)
                                  : '${m.homeTeamScore} – ${m.awayTeamScore}',
                              style: GoogleFonts.inter(
                                fontSize: isUpcoming ? 14 : 18,
                                fontWeight: FontWeight.w900,
                                color: isLive ? primary : textPri,
                              ),
                            ),
                            if (!isLive && !isUpcoming)
                              Text('FT',
                                  style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: textSec,
                                      letterSpacing: 0.8)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Image.asset(m.awayTeam.logo,
                                width: 28, height: 28),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(m.awayTeam.name,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textPri),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _liveDot(Color primary) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.4, end: 1.0),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        builder: (_, v, child) => Opacity(opacity: v, child: child),
        child: Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary,
            boxShadow: [
              BoxShadow(
                  color: primary.withValues(alpha: 0.7),
                  blurRadius: 6)
            ],
          ),
        ),
      );

  // ── Standings Tab ────────────────────────────────────
  Widget _standingsTab(
    League league,
    bool isDark,
    Color primary,
    Color cardBg,
    Color textPri,
    Color textSec,
    Color divider,
  ) {
    final sorted = [...league.teams]..sort((a, b) {
        if ((b.points ?? 0) != (a.points ?? 0))
          return (b.points ?? 0).compareTo(a.points ?? 0);
        final da = (a.goalsFor ?? 0) - (a.goalsAgainst ?? 0);
        final db = (b.goalsFor ?? 0) - (b.goalsAgainst ?? 0);
        return db.compareTo(da);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divider),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 14,
              headingRowHeight: 42,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 52,
              headingRowColor: WidgetStateProperty.all(
                  isDark ? const Color(0xFF252525) : const Color(0xFFF4F4F4)),
              columns: [
                DataColumn(
                    label: Text('#',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: textSec))),
                DataColumn(
                    label: Text('TEAM',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: textSec))),
                DataColumn(
                    label: Text('P',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: textSec))),
                DataColumn(
                    label: Text('W',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: textSec))),
                DataColumn(
                    label: Text('D',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: textSec))),
                DataColumn(
                    label: Text('L',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: textSec))),
                DataColumn(
                    label: Text('GD',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: textSec))),
                DataColumn(
                    label: Text('DIFF',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: textSec))),
                DataColumn(
                    label: Text('PTS',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: textSec))),
              ],
              rows: List.generate(sorted.length, (i) {
                final t = sorted[i];
                final diff = (t.goalsFor ?? 0) - (t.goalsAgainst ?? 0);
                final isTop = i < 3;
                return DataRow(cells: [
                  DataCell(Text('${i + 1}',
                      style: GoogleFonts.inter(
                          fontWeight: isTop ? FontWeight.w800 : FontWeight.w400,
                          color: isTop ? primary : textSec,
                          fontSize: 13))),
                  DataCell(Row(children: [
                    Image.asset(t.logo, width: 24, height: 24),
                    const SizedBox(width: 8),
                    Text(t.name,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: textPri)),
                  ])),
                  DataCell(Text('${t.played ?? 0}',
                      style: GoogleFonts.inter(fontSize: 13, color: textPri))),
                  DataCell(Text('${t.wins ?? 0}',
                      style: GoogleFonts.inter(fontSize: 13, color: textPri))),
                  DataCell(Text('${t.draw ?? 0}',
                      style: GoogleFonts.inter(fontSize: 13, color: textPri))),
                  DataCell(Text('${t.losses ?? 0}',
                      style: GoogleFonts.inter(fontSize: 13, color: textPri))),
                  DataCell(Text('${t.goalsFor ?? 0}',
                      style: GoogleFonts.inter(fontSize: 13, color: textPri))),
                  DataCell(Text(
                      diff > 0 ? '+$diff' : '$diff',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: diff > 0
                              ? primary
                              : diff < 0
                                  ? AppColors.darkError
                                  : textSec))),
                  DataCell(Text('${t.points ?? 0}',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: primary))),
                ]);
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ── Leaders Tab ──────────────────────────────────────
  Widget _leadersTab(
    League league,
    bool isDark,
    Color primary,
    Color cardBg,
    Color textPri,
    Color textSec,
    Color divider,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: textSec,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Top Scorers'),
                  Tab(text: 'Top Assists'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _leaderboard(league.topScorers ?? [], 'goals', league,
                    isDark, primary, cardBg, textPri, textSec),
                _leaderboard(league.topAssistants ?? [], 'assists', league,
                    isDark, primary, cardBg, textPri, textSec),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderboard(
    List<Player> players,
    String stat,
    League league,
    bool isDark,
    Color primary,
    Color cardBg,
    Color textPri,
    Color textSec,
  ) {
    if (players.isEmpty) {
      return Center(
          child: Text('No data available',
              style: GoogleFonts.inter(fontSize: 14, color: textSec)));
    }
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: players.length,
      itemBuilder: (_, i) {
        final p = players[i];
        final val = stat == 'goals' ? p.goals : p.assists;
        final teamCandidates = league.teams.where(
          (t) => t.players.any(
              (tp) => tp.backendId == p.backendId || tp.name == p.name),
        );
        final hasTeam = teamCandidates.isNotEmpty;
        final teamName = hasTeam ? teamCandidates.first.name : 'Unknown';
        final teamLogo = hasTeam
            ? teamCandidates.first.logo
            : 'asset/Teams_Logo/1.png';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlayerDetailsPage(player: p)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: divider),
            ),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 28,
                  alignment: Alignment.center,
                  child: i < 3
                      ? Icon(
                          Icons.workspace_premium_rounded,
                          color: i == 0
                              ? const Color(0xFFFFD700)
                              : i == 1
                                  ? const Color(0xFFC0C0C0)
                                  : const Color(0xFFCD7F32),
                          size: 22,
                        )
                      : Text('${i + 1}',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textSec)),
                ),
                const SizedBox(width: 12),
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(p.name[0].toUpperCase(),
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: primary)),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: Image.asset(teamLogo, width: 14, height: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPri)),
                      Text(teamName,
                          style:
                              GoogleFonts.inter(fontSize: 12, color: textSec)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$val',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: primary)),
                    Text(stat.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: textSec,
                            letterSpacing: 0.8)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
