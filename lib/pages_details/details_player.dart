import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/player_stats_model.dart';
import 'package:offside/theme_provider.dart';

class PlayerDetailsPage extends StatelessWidget {
  final Player player;
  const PlayerDetailsPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkBg : Colors.white;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPri = isDark ? AppColors.darkTextPri : AppColors.lightTextPri;
    final textSec = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final heroGradient = isDark
        ? [const Color(0xFF001F24), AppColors.darkBg]
        : [Colors.white, Colors.white];

    final statsBox = Hive.box<PlayerStats>('player_stats');
    final List<PlayerStats> pStats = statsBox.values
        .where((s) => s.playerId == player.backendId)
        .toList();

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: heroGradient[0],
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded,
                  color: isDark ? Colors.white : textPri, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: heroGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar with Neon Blue Circle (Standardized for both modes)
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primary, width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 16)
                          ],
                          image: (player.image != null &&
                                  player.image!.isNotEmpty)
                              ? DecorationImage(
                                  fit: BoxFit.cover,
                                  image: player.image!.startsWith('http')
                                      ? NetworkImage(player.image!)
                                      : AssetImage(player.image!)
                                          as ImageProvider,
                                )
                              : null,
                        ),
                        child: (player.image == null || player.image!.isEmpty)
                            ? Center(
                                child: Text(
                                  player.name[0].toUpperCase(),
                                  style: GoogleFonts.inter(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : primary),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Text(player.name,
                          style: GoogleFonts.inter(
                              color: isDark ? Colors.white : textPri,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _chip(player.position, primary, isDark),
                          const SizedBox(width: 8),
                          _chip('#${player.number}', primary, isDark),
                          const SizedBox(width: 8),
                          _chip(player.nationality, primary, isDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Bio row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: divider),
                    boxShadow: isDark ? [] : [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _bioItem('Height',
                          '${player.height?.toInt() ?? '-'} cm', primary, textPri, textSec),
                      _dividerV(divider),
                      _bioItem('Weight',
                          '${player.weight?.toInt() ?? '-'} kg', primary, textPri, textSec),
                      _dividerV(divider),
                      _bioItem('Age', '${player.age}', primary, textPri, textSec),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _sectionTitle('Career Statistics', textSec),
                const SizedBox(height: 10),

                // Stats grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 0.95,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _statCard('Apps', '${player.appearances}',
                        Icons.event_available_outlined, AppColors.darkSecondary,
                        cardBg, textPri, textSec, divider, isDark),
                    _statCard('Goals', '${player.goals}',
                        Icons.sports_soccer, primary, cardBg, textPri, textSec, divider, isDark),
                    _statCard('Assists', '${player.assists}',
                        Icons.assistant_outlined, AppColors.darkAccent,
                        cardBg, textPri, textSec, divider, isDark),
                    _statCard('Top Speed',
                        '${player.highestSpeed?.toStringAsFixed(1) ?? '0'} km/h',
                        Icons.speed_outlined, const Color(0xFFFF4081),
                        cardBg, textPri, textSec, divider, isDark),
                    _statCard('Yellow',
                        '${player.yellowCards}', Icons.square_rounded,
                        const Color(0xFFFFC107), cardBg, textPri, textSec, divider, isDark),
                    _statCard('Red', '${player.redCards}',
                        Icons.square_rounded, AppColors.darkError,
                        cardBg, textPri, textSec, divider, isDark),
                  ],
                ),

                const SizedBox(height: 24),
                _sectionTitle('Recent Matches', textSec),
                const SizedBox(height: 10),

                _buildMatchHistory(context, isDark, primary, cardBg,
                    textPri, textSec, divider, pStats),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistory(BuildContext context, bool isDark, Color primary,
      Color cardBg, Color textPri, Color textSec, Color divider, List<PlayerStats> pStats) {
    final leaguesBox = Hive.box<League>('leagues');

    if (pStats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No match history available',
              style: GoogleFonts.inter(fontSize: 14, color: textSec)),
        ),
      );
    }

    return Column(
      children: pStats.map((stat) {
        Match2? match;
        for (var l in leaguesBox.values) {
          for (var m in l.matches) {
            if (m.backendId == stat.matchId) {
              match = m;
              break;
            }
          }
          if (match != null) break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: divider),
            boxShadow: isDark ? [] : [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.sports_soccer_outlined, color: primary, size: 20),
              ),
              title: Text(
                match != null
                    ? '${match.homeTeam.name} vs ${match.awayTeam.name}'
                    : 'Match',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: textPri),
              ),
              subtitle: Text(
                'Goals: ${stat.goals ?? 0} · Assists: ${stat.assists ?? 0}${(stat.isMvp ?? false) ? ' · ⭐ MVP' : ''}',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: (stat.isMvp ?? false) ? const Color(0xFFFFD700) : textSec),
              ),
              iconColor: primary,
              collapsedIconColor: textSec,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _smallStat('Top Speed',
                        '${stat.topSpeed?.toStringAsFixed(1) ?? '-'} km/h',
                        primary, textPri, textSec),
                    _smallStat('Distance',
                        '${stat.totalDistance?.toStringAsFixed(1) ?? '-'} km',
                        primary, textPri, textSec),
                    _smallStat('Possession',
                        '${stat.acquisition?.toStringAsFixed(0) ?? '-'}%',
                        primary, textPri, textSec),
                  ],
                ),
                if (stat.heatmapImageUrl != null && stat.heatmapImageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Match Heatmap', textSec),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      stat.heatmapImageUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _chip(String label, Color primary, bool isDark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      );

  Widget _bioItem(String label, String value, Color primary, Color textPri, Color textSec) =>
      Column(children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: textPri)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: textSec)),
      ]);

  Widget _dividerV(Color divider) =>
      Container(width: 1, height: 40, color: divider);

  Widget _sectionTitle(String title, Color textSec) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(title.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textSec,
                letterSpacing: 1.2)),
      );

  Widget _statCard(String label, String value, IconData icon, Color color,
      Color cardBg, Color textPri, Color textSec, Color divider, bool isDark) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: divider),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: textPri),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(fontSize: 10, color: textSec),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  Widget _smallStat(String label, String value, Color primary, Color textPri, Color textSec) =>
      Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPri)),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: textSec)),
        ],
      );
}

class PitchPainter extends CustomPainter {
  final Color color;
  PitchPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 40, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
