import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/services/api_service.dart';
import 'package:offside/theme_provider.dart';

class FavoritesPage extends StatefulWidget {
  final String userRole;
  final String? userName;

  const FavoritesPage({super.key, required this.userRole, this.userName});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {

  Team? _selectedTeam;
  Player? _selectedPlayer;
  bool _loading = true;
  bool _saving = false;

  List<Team> _allTeams = [];
  List<Player> _allPlayers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // 1. Load data lists from Hive
      final leagues = Hive.box<League>('leagues').values.toList();
      final allTeams = leagues.expand((l) => l.teams).toList();
      _allTeams = {for (var t in allTeams) t.name: t}.values.toList();

      _allPlayers = Hive.box<Player>('players').values.toList();

      // 2. Load locally saved favorites first (offline fallback)
      final favBox = await Hive.openBox('favorites');
      final localTeamName = favBox.get('favorite_team') as String?;
      final localPlayerName = favBox.get('favorite_player') as String?;

      if (localTeamName != null && localTeamName.isNotEmpty) {
        _selectedTeam = _allTeams.firstWhere(
          (t) => t.name == localTeamName,
          orElse: () => Team(name: localTeamName, logo: 'asset/Teams_Logo/1.png', players: []),
        );
      }

      if (localPlayerName != null && localPlayerName.isNotEmpty) {
        _selectedPlayer = _allPlayers.firstWhere(
          (p) => p.name == localPlayerName,
          orElse: () => Player(name: localPlayerName, position: '', age: 0, nationality: '', number: 0),
        );
      }

      // 3. Load from API if connected
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        final data = await ApiService.fetchUserData(user.email!);
        if (data != null) {

          
          final apiTeamName = data['favorite_team']?.toString();
          final apiPlayerName = data['favorite_player']?.toString();

          if (apiTeamName != null && apiTeamName.isNotEmpty) {
            setState(() {
              _selectedTeam = _allTeams.firstWhere(
                (t) => t.name == apiTeamName,
                orElse: () => Team(name: apiTeamName, logo: 'asset/Teams_Logo/1.png', players: []),
              );
            });
            await favBox.put('favorite_team', apiTeamName);
          }

          if (apiPlayerName != null && apiPlayerName.isNotEmpty) {
            setState(() {
              _selectedPlayer = _allPlayers.firstWhere(
                (p) => p.name == apiPlayerName,
                orElse: () => Player(name: apiPlayerName, position: '', age: 0, nationality: '', number: 0),
              );
            });
            await favBox.put('favorite_player', apiPlayerName);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveFavorites() async {
    setState(() => _saving = true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      // 1. Save locally to Hive box
      final favBox = Hive.box('favorites');
      await favBox.put('favorite_team', _selectedTeam?.name ?? '');
      await favBox.put('favorite_player', _selectedPlayer?.name ?? '');

      // 2. Try to sync to the backend API
      final email = widget.userName ?? Supabase.instance.client.auth.currentUser?.email;
      if (email != null) {
        await ApiService.updateUserProfile(
          email: email,
          role: widget.userRole,
          updates: {
            'favorite_team': _selectedTeam?.name ?? '',
            'favorite_player': _selectedPlayer?.name ?? '',
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Favorites updated and synced successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
          backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('API Sync failed, saved locally: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Saved locally! Sync pending connection.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showTeamSelector(Color primary, Color cardBg, Color textPri, Color textSec, Color divider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _allTeams
                .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Select Favorite Team',
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w700, color: textPri)),
                  const SizedBox(height: 16),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF252525)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (v) => setModalState(() => query = v),
                      style: GoogleFonts.inter(color: textPri, fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search teams...',
                        hintStyle: GoogleFonts.inter(color: textSec, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: textSec, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final t = filtered[i];
                        return ListTile(
                          leading: Image.asset(t.logo, width: 32, height: 32),
                          title: Text(t.name,
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: textPri)),
                          onTap: () {
                            setState(() => _selectedTeam = t);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPlayerSelector(Color primary, Color cardBg, Color textPri, Color textSec, Color divider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _allPlayers
                .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Select Favorite Player',
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w700, color: textPri)),
                  const SizedBox(height: 16),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF252525)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (v) => setModalState(() => query = v),
                      style: GoogleFonts.inter(color: textPri, fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search players...',
                        hintStyle: GoogleFonts.inter(color: textSec, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: textSec, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primary.withValues(alpha: 0.1),
                            child: Text(p.name[0].toUpperCase(),
                                style: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w700)),
                          ),
                          title: Text(p.name,
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: textPri)),
                          subtitle: Text(p.position,
                              style: GoogleFonts.inter(fontSize: 12, color: textSec)),
                          onTap: () {
                            setState(() => _selectedPlayer = p);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 18, color: textPri),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Favorite Selections',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: textPri)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set your favorite team and player to personalize your dashboard and get highlights.',
                      style: GoogleFonts.inter(fontSize: 13, color: textSec)),
                  const SizedBox(height: 24),

                  // ── Favorite Team Selection ────────────────
                  Text('FAVORITE TEAM',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w800, color: textSec, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showTeamSelector(primary, cardBg, textPri, textSec, divider),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: divider),
                      ),
                      child: Row(
                        children: [
                          if (_selectedTeam != null) ...[
                            Image.asset(_selectedTeam!.logo, width: 44, height: 44),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(_selectedTeam!.name,
                                  style: GoogleFonts.inter(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: textPri)),
                            ),
                          ] else ...[
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.shield_outlined, color: primary, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text('Select Favorite Team',
                                  style: GoogleFonts.inter(
                                      fontSize: 14, color: textSec, fontWeight: FontWeight.w500)),
                            ),
                          ],
                          Icon(Icons.chevron_right, color: textSec, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Favorite Player Selection ──────────────
                  Text('FAVORITE PLAYER',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w800, color: textSec, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showPlayerSelector(primary, cardBg, textPri, textSec, divider),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: divider),
                      ),
                      child: Row(
                        children: [
                          if (_selectedPlayer != null) ...[
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(_selectedPlayer!.name[0].toUpperCase(),
                                    style: GoogleFonts.inter(
                                        color: primary, fontWeight: FontWeight.w800, fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedPlayer!.name,
                                      style: GoogleFonts.inter(
                                          fontSize: 15, fontWeight: FontWeight.w700, color: textPri)),
                                  const SizedBox(height: 3),
                                  Text('${_selectedPlayer!.position} • Jersey #${_selectedPlayer!.number}',
                                      style: GoogleFonts.inter(fontSize: 12, color: textSec)),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person_outline, color: primary, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text('Select Favorite Player',
                                  style: GoogleFonts.inter(
                                      fontSize: 14, color: textSec, fontWeight: FontWeight.w500)),
                            ),
                          ],
                          Icon(Icons.chevron_right, color: textSec, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── Save Button ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveFavorites,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                            )
                          : Text('Save Favorites',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
