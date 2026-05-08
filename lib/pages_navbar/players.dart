import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/pages_details/details_player.dart';
import 'package:offside/services/sync_service.dart';
import 'package:offside/theme_provider.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  final playersBox = Hive.box<Player>('players');
  String searchQuery = '';
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _refreshPlayers();
  }

  Future<void> _refreshPlayers() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    await SyncService.fetchAllLeaguesFromBackend();
    if (mounted) setState(() => _isSyncing = false);
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text('Players',
                      style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPri)),
                  const Spacer(),
                  _isSyncing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: primary))
                      : GestureDetector(
                          onTap: _refreshPlayers,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: divider),
                              boxShadow: isDark ? [] : [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)
                              ],
                            ),
                            child: Icon(Icons.sync,
                                color: primary, size: 18),
                          ),
                        ),
                ],
              ),
            ),

            // ── Search Bar ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? cardBg : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: divider),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => searchQuery = v),
                  style: GoogleFonts.inter(color: textPri, fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search players…',
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

            // ── Player List ──────────────────────────────
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: playersBox.listenable(),
                builder: (context, box, _) {
                  final players = playersBox.values
                      .where((p) => p.name
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()))
                      .toList();

                  if (_isSyncing && players.isEmpty) {
                    return Center(
                        child: CircularProgressIndicator(color: primary));
                  }

                  if (players.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined,
                              size: 64,
                              color: textSec.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No players found',
                              style: GoogleFonts.inter(
                                  fontSize: 15, color: textSec)),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _refreshPlayers,
                            icon: Icon(Icons.sync, color: primary),
                            label: Text('Sync Data',
                                style: GoogleFonts.inter(color: primary)),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: primary,
                    onRefresh: _refreshPlayers,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: players.length,
                      itemBuilder: (context, i) {
                        final p = players[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: divider),
                            boxShadow: isDark ? [] : [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
                            ],
                          ),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      PlayerDetailsPage(player: p)),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // Avatar with blue circle (matching dark mode style)
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: primary, width: 2),
                                      boxShadow: [
                                        BoxShadow(color: primary.withValues(alpha: 0.1), blurRadius: 8)
                                      ],
                                    ),
                                    child: p.image != null &&
                                            p.image!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.asset(p.image!,
                                                fit: BoxFit.cover))
                                        : Icon(Icons.person,
                                            color: primary, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name,
                                            style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: textPri)),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${p.position} • Jersey #${p.number}',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: textSec),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Position badge (solid primary with white text in light mode)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? primary.withValues(alpha: 0.15) : primary,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      p.position.isNotEmpty
                                          ? p.position
                                              .substring(0, p.position.length > 3 ? 3 : p.position.length)
                                              .toUpperCase()
                                          : '—',
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.chevron_right,
                                      size: 18, color: textSec),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
