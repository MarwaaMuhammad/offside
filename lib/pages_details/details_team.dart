import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/pages_details/details_match.dart';
import 'package:offside/pages_details/details_player.dart';
import 'package:offside/theme_provider.dart';

class TeamDetailsPage extends StatefulWidget {
  final Team team;
  final League league;

  const TeamDetailsPage({super.key, required this.team, required this.league});

  @override
  State<TeamDetailsPage> createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends State<TeamDetailsPage>
    with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkBg : Colors.white;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPri = isDark ? AppColors.darkTextPri : AppColors.lightTextPri;
    final textSec = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    const darkBlueBg = Color(0xFF001F24);

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? darkBlueBg : primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [darkBlueBg, AppColors.darkBg]
                        : [primary, primary.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Hero(
                        tag: 'team_logo_${widget.team.name}',
                        child: Container(
                          width: 72, height: 72,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: Image.asset(widget.team.logo),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(widget.team.name.toUpperCase(),
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      // Kit colors
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _kitDot(widget.team.primaryColor),
                          const SizedBox(width: 4),
                          _kitDot(widget.team.secondaryColor),
                          const SizedBox(width: 4),
                          _kitDot(widget.team.goalkeeperColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              labelStyle:
                  GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Matches'),
                Tab(text: 'Standings'),
                Tab(text: 'Squad'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _matchesTab(isDark, primary, cardBg, textPri, textSec, divider),
            _standingsTab(isDark, primary, cardBg, textPri, textSec, divider),
            _squadTab(isDark, primary, cardBg, textPri, textSec, divider),
          ],
        ),
      ),
    );
  }

  Widget _kitDot(String? hexColor) {
    if (hexColor == null) return const SizedBox.shrink();
    try {
      return Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: Color(int.parse(hexColor.replaceAll('#', '0xFF'))),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12, width: 0.5),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _matchesTab(bool isDark, Color primary, Color cardBg, Color textPri,
      Color textSec, Color divider) {
    final now = DateTime.now();
    final teamMatches = widget.league.matches.where((m) =>
        (m.homeTeam.backendId != null &&
            m.homeTeam.backendId == widget.team.backendId) ||
        (m.awayTeam.backendId != null &&
            m.awayTeam.backendId == widget.team.backendId) ||
        m.homeTeam.name == widget.team.name ||
        m.awayTeam.name == widget.team.name).toList();

    if (teamMatches.isEmpty) {
      return Center(
          child: Text('No matches found',
              style: GoogleFonts.inter(fontSize: 14, color: textSec)));
    }

    final byDate = <String, List<dynamic>>{};
    for (var m in teamMatches) {
      byDate.putIfAbsent(DateFormat('yyyy-MM-dd').format(m.date), () => []).add(m);
    }

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
                  Text(DateFormat('EEEE, dd MMM').format(matches.first.date),
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primary,
                          letterSpacing: 0.8)),
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
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MatchDetailsPage(match: m, league: widget.league),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: divider),
                    boxShadow: isDark ? [] : [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)
                    ],
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
                            Image.asset(m.homeTeam.logo, width: 28, height: 28),
                          ],
                        ),
                      ),
                      Container(
                        width: 72,
                        alignment: Alignment.center,
                        child: Text(
                          isUpcoming
                              ? DateFormat('HH:mm').format(m.date)
                              : '${m.homeTeamScore} – ${m.awayTeamScore}',
                          style: GoogleFonts.inter(
                              fontSize: isUpcoming ? 14 : 18,
                              fontWeight: FontWeight.w900,
                              color: textPri),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Image.asset(m.awayTeam.logo, width: 28, height: 28),
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

  Widget _standingsTab(bool isDark, Color primary, Color cardBg, Color textPri,
      Color textSec, Color divider) {
    widget.league.updateStandings();
    final sorted = [...widget.league.teams]..sort((a, b) {
        if ((b.points ?? 0) != (a.points ?? 0))
          return (b.points ?? 0).compareTo(a.points ?? 0);
        return ((b.goalsFor ?? 0) - (b.goalsAgainst ?? 0))
            .compareTo((a.goalsFor ?? 0) - (a.goalsAgainst ?? 0));
      });

    final currentTeam = sorted.firstWhere(
        (t) => (t.backendId != null && t.backendId == widget.team.backendId) ||
            t.name == widget.team.name,
        orElse: () => widget.team);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dashboard Metrics (Filling white part) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 15, offset: const Offset(0, 8))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _dashItem('RANK', '#${sorted.indexOf(currentTeam) + 1}'),
                _dashItem('POINTS', '${currentTeam.points ?? 0}'),
                _dashItem('PLAYED', '${currentTeam.played ?? 0}'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── League Table Container ────────────────
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: divider),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12)
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50],
                    child: Text('STANDINGS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: textSec, letterSpacing: 0.5)),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
                      child: DataTable(
                        columnSpacing: 10,
                        horizontalMargin: 12,
                        headingRowHeight: 40,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 52,
                        headingRowColor: WidgetStateProperty.all(Colors.transparent),
                        columns: ['#', 'TEAM', 'P', 'W', 'D', 'L', 'GD', 'PTS']
                            .map((c) => DataColumn(
                                  label: Text(c,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          color: textSec)),
                                ))
                            .toList(),
                        rows: List.generate(sorted.length, (i) {
                          final t = sorted[i];
                          final isCurrent = (t.backendId != null &&
                                  t.backendId == widget.team.backendId) ||
                              t.name == widget.team.name;
                          return DataRow(
                            color: isCurrent
                                ? WidgetStateProperty.all(primary.withValues(alpha: 0.08))
                                : (i % 2 != 0 ? WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.01) : Colors.grey[50]!.withValues(alpha: 0.3)) : null),
                            cells: [
                              DataCell(Center(
                                child: Text('${i + 1}',
                                    style: GoogleFonts.inter(
                                        fontWeight: isCurrent
                                            ? FontWeight.w800
                                            : FontWeight.w400,
                                        color: isCurrent ? primary : textSec,
                                        fontSize: 13)),
                              )),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(t.logo, width: 22, height: 22),
                                  const SizedBox(width: 8),
                                  Text(t.name,
                                      style: GoogleFonts.inter(
                                          fontWeight: isCurrent
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          fontSize: 13,
                                          color: isCurrent ? primary : textPri)),
                                ],
                              )),
                              DataCell(Center(child: Text('${t.played ?? 0}', style: GoogleFonts.inter(fontSize: 13, color: textPri)))),
                              DataCell(Center(child: Text('${t.wins ?? 0}', style: GoogleFonts.inter(fontSize: 13, color: textPri)))),
                              DataCell(Center(child: Text('${t.draw ?? 0}', style: GoogleFonts.inter(fontSize: 13, color: textPri)))),
                              DataCell(Center(child: Text('${t.losses ?? 0}', style: GoogleFonts.inter(fontSize: 13, color: textPri)))),
                              DataCell(Center(child: Text('${(t.goalsFor ?? 0) - (t.goalsAgainst ?? 0)}', style: GoogleFonts.inter(fontSize: 13, color: textPri)))),
                              DataCell(Center(child: Text('${t.points ?? 0}',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: isCurrent ? primary : textPri)))),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
      ],
    );
  }

  Widget _squadTab(bool isDark, Color primary, Color cardBg, Color textPri,
      Color textSec, Color divider) {
    if (widget.team.players.isEmpty) {
      return Center(
          child: Text('No players in squad',
              style: GoogleFonts.inter(fontSize: 14, color: textSec)));
    }
    final sorted = [...widget.team.players]..sort((a, b) => a.number.compareTo(b.number));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final p = sorted[i];
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
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6)
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Center(
                    child: Text(p.name[0].toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: primary)),
                  ),
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
                      Text(p.position,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: textSec)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? primary.withValues(alpha: 0.15) : primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('#${p.number}',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
