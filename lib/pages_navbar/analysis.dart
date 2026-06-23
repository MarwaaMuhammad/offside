import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/pages_details/details_league.dart';
import 'package:offside/pages_details/details_team.dart';
import 'package:offside/theme_provider.dart';

class AnalysisPage extends StatefulWidget {
  final String userRole;
  const AnalysisPage({super.key, this.userRole = 'user'});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final leaguesBox = Hive.box<League>('leagues');
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPri = isDark ? AppColors.darkTextPri : AppColors.lightTextPri;
    final textSec = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Analysis',
                          style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textPri)),
                      Text('Leagues & Teams',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: textSec)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Search Bar ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: divider),
                ),
                child: TextField(
                  onChanged: (v) =>
                      setState(() => searchQuery = v.toLowerCase()),
                  style: GoogleFonts.inter(
                      color: textPri, fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search leagues or teams…',
                    hintStyle:
                        GoogleFonts.inter(color: textSec, fontSize: 13),
                    prefixIcon:
                        Icon(Icons.search, color: textSec, size: 20),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Results ────────────────────────────────
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: leaguesBox.listenable(),
                builder: (context, Box<League> box, _) {
                  final all = box.values.toList();
                  final filteredLeagues = searchQuery.isEmpty
                      ? all
                      : all
                          .where((l) =>
                              l.name.toLowerCase().contains(searchQuery))
                          .toList();

                  List<({Team team, League league})> filteredTeams = [];
                  if (searchQuery.isNotEmpty) {
                    for (var l in all) {
                      for (var t in l.teams) {
                        if (t.name.toLowerCase().contains(searchQuery)) {
                          filteredTeams.add((team: t, league: l));
                        }
                      }
                    }
                  }

                  if (filteredLeagues.isEmpty && filteredTeams.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            all.isEmpty
                                ? Icons.sports_soccer_outlined
                                : Icons.search_off_outlined,
                            size: 64,
                            color: textSec.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            all.isEmpty
                                ? 'No leagues yet.\nTap Create Match in the navigation bar to create one!'
                                : 'No results found',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 15, color: textSec),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    children: [
                      if (filteredLeagues.isNotEmpty) ...[
                        _label('LEAGUES', primary),
                        const SizedBox(height: 6),
                        ...filteredLeagues
                            .map((l) => _leagueTile(l, isDark, primary,
                                textPri, textSec, divider))
                            .toList(),
                        const SizedBox(height: 16),
                      ],
                      if (filteredTeams.isNotEmpty) ...[
                        _label('TEAMS', primary),
                        const SizedBox(height: 6),
                        ...filteredTeams
                            .map((e) => _teamTile(e.team, e.league, isDark,
                                primary, textPri, textSec, divider))
                            .toList(),
                      ],
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

  Widget _label(String text, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _leagueTile(League l, bool isDark, Color primary, Color textPri,
      Color textSec, Color divider) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LeaguePage(league: l)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divider),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'league_logo_${l.name}_${l.backendId}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(l.logo, width: 44, height: 44),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.name,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPri)),
                  Text(
                    '${l.teams.length} teams • ${l.matches.length} matches',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: textSec),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primary)),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_forward_ios,
                      size: 10, color: primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamTile(Team t, League l, bool isDark, Color primary,
      Color textPri, Color textSec, Color divider) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TeamDetailsPage(team: t, league: l)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divider),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'team_logo_${t.name}_${t.backendId}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(t.logo, width: 40, height: 40),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPri)),
                  Text(l.name,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: primary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: textSec),
          ],
        ),
      ),
    );
  }
}
