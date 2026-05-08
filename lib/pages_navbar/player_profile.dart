import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/models/player_stats_model.dart';
import 'package:offside/services/sync_service.dart';
import 'package:offside/theme_provider.dart';

class PlayerProfilePage extends StatefulWidget {
  final String playerName;
  const PlayerProfilePage({super.key, required this.playerName});

  @override
  State<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage>
    with SingleTickerProviderStateMixin {
  final playerBox = Hive.box<Player>('players');
  final leaguesBox = Hive.box<League>('leagues');
  final statsBox = Hive.box<PlayerStats>('player_stats');
  final ImagePicker _picker = ImagePicker();
  bool _isSyncing = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isSyncing = true);
    await SyncService.fetchAllLeaguesFromBackend();
    if (mounted) setState(() => _isSyncing = false);
  }

  Future<void> _pickImage(Player player, ImageSource source) async {
    final XFile? img = await _picker.pickImage(source: source);
    if (img != null) {
      setState(() {
        player.image = img.path;
        player.save();
      });
    }
  }

  void _showPicker(Player player, bool isDark, Color primary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Update Profile Photo',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPri
                          : AppColors.lightTextPri)),
              const SizedBox(height: 8),
              _sheetOption(Icons.photo_library_outlined, 'Gallery', primary,
                  isDark, () {
                Navigator.pop(context);
                _pickImage(player, ImageSource.gallery);
              }),
              _sheetOption(Icons.camera_alt_outlined, 'Camera', primary, isDark,
                  () {
                Navigator.pop(context);
                _pickImage(player, ImageSource.camera);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption(IconData icon, String label, Color primary, bool isDark,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primary, size: 20),
            ),
            const SizedBox(width: 16),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    color:
                        isDark ? AppColors.darkTextPri : AppColors.lightTextPri,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
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
      body: ValueListenableBuilder(
        valueListenable: playerBox.listenable(),
        builder: (context, Box<Player> box, _) {
          final players =
              box.values.where((p) => p.name == widget.playerName).toList();

          if (players.isEmpty) {
            return _emptyState(primary, textSec);
          }

          final player = players.first;
          final isMvp = player.goals >= 3;

          List<Team> joinedTeams = [];
          for (var l in leaguesBox.values) {
            for (var t in l.teams) {
              if (t.players.any((p) => p.name == widget.playerName)) {
                joinedTeams.add(t);
              }
            }
          }

          // Fetch stats for Recent Matches heatmap
          final List<PlayerStats> pStats = statsBox.values
              .where((s) => s.playerId == player.backendId)
              .toList();

          return CustomScrollView(
            slivers: [
              // ── Hero Header ──────────────────────────
              SliverToBoxAdapter(
                child: _buildHeroHeader(
                    player, isMvp, isDark, primary, textPri, textSec, bg),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),

                    // ── Stats ──────────────────────────
                    _sectionTitle('Performance Overview', textSec),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.0,
                      children: [
                        _statCard('Goals', '${player.goals}',
                            Icons.sports_soccer, AppColors.darkPrimary,
                            cardBg, textPri, textSec, divider),
                        _statCard('Assists', '${player.assists}',
                            Icons.assistant_outlined, AppColors.darkAccent,
                            cardBg, textPri, textSec, divider),
                        _statCard('Appearances', '${player.appearances}',
                            Icons.event_outlined, AppColors.darkSecondary,
                            cardBg, textPri, textSec, divider),
                        _statCard(
                            'Top Speed',
                            '${player.highestSpeed?.toStringAsFixed(1) ?? "0.0"} km/h',
                            Icons.speed_outlined,
                            const Color(0xFFFF4081),
                            cardBg,
                            textPri,
                            textSec,
                            divider),
                        _statCard(
                            'Distance',
                            '${((player.totalDistance ?? 0) / 1000).toStringAsFixed(2)} km',
                            Icons.directions_run_outlined,
                            const Color(0xFF7C4DFF),
                            cardBg,
                            textPri,
                            textSec,
                            divider),
                        _statCard(
                            'Cards',
                            '${player.yellowCards}Y / ${player.redCards}R',
                            Icons.style_outlined,
                            const Color(0xFFFFC107),
                            cardBg,
                            textPri,
                            textSec,
                            divider),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Heatmap removed from main profile body as per request

                    // ── Teams ──────────────────────────
                    _sectionTitle('Teams & Organizations', textSec),
                    const SizedBox(height: 10),
                    if (joinedTeams.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: divider),
                        ),
                        child: Center(
                          child: Text('Not assigned to any team yet.',
                              style: GoogleFonts.inter(
                                  color: textSec, fontSize: 14)),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: divider),
                        ),
                        child: Column(
                          children: joinedTeams.asMap().entries.map((e) {
                            final team = e.value;
                            final isLast =
                                e.key == joinedTeams.length - 1;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Image.asset(team.logo,
                                            width: 38, height: 38),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(team.name,
                                                style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: textPri)),
                                            Text('Active Member',
                                                style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: primary)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? primary.withValues(alpha: 0.15) : primary,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text('Active',
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  Divider(
                                      height: 1,
                                      color: divider,
                                      indent: 68),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(Player player, bool isMvp, bool isDark,
      Color primary, Color textPri, Color textSec, Color bg) {
    const darkBlueBg = Color(0xFF001F24);
    String displayId = (player.backendId != null && player.backendId!.length >= 6)
        ? player.backendId!.substring(0, 6)
        : (player.backendId ?? 'N/A');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? null : Colors.white,
        gradient: isDark ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [darkBlueBg, AppColors.darkBg],
        ) : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // AppBar row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        size: 18, color: textPri),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('Player Profile',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPri)),
                  const Spacer(),
                  _isSyncing
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: primary)),
                        )
                      : IconButton(
                          icon: Icon(Icons.refresh, color: primary),
                          onPressed: _refreshData,
                        ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Avatar & Info
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showPicker(player, isDark, primary),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primary, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 16,
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: isDark
                                ? AppColors.darkCard : Colors.white,
                            backgroundImage: player.image != null &&
                                    player.image!.isNotEmpty &&
                                    !player.image!.startsWith('asset')
                                ? FileImage(File(player.image!))
                                : (player.image != null &&
                                        player.image!.startsWith('asset')
                                    ? AssetImage(player.image!)
                                    : null) as ImageProvider?,
                            child: player.image == null ||
                                    player.image!.isEmpty
                                ? Icon(Icons.person,
                                    size: 50, color: textSec)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: primary, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: Colors.black),
                          ),
                        ),
                        if (isMvp)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: AppColors.darkAccent,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.star,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.name,
                            style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: textPri,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? primary.withValues(alpha: 0.15) : primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'PRO PLAYER',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('ID: $displayId',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: textSec)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Text(title,
        style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.2));
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      Color bg, Color textPri, Color textSec, Color divider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPri)),
                Text(label,
                    style: GoogleFonts.inter(fontSize: 11, color: textSec)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(Color primary, Color textSec) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 80, color: textSec.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Player not found',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: textSec)),
          const SizedBox(height: 8),
          Text('Try searching for another name',
              style: GoogleFonts.inter(color: textSec, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          )
        ],
      ),
    );
  }
}
