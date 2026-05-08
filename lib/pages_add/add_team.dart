import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/pages_add/add_matches.dart';
import 'package:offside/pages_add/add_player.dart';
import 'package:offside/theme_provider.dart';

class CreateTeamPage extends StatefulWidget {
  final String leagueName;
  final String logo;
  final DateTime? startDate;
  final DateTime? endDate;

  const CreateTeamPage({
    super.key,
    required this.leagueName,
    required this.logo,
    this.startDate,
    this.endDate,
  });

  @override
  State<CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  final _nameController = TextEditingController();
  Color _primaryColor = const Color(0xFF0066FF); // Dark Neon Blue
  Color _secondaryColor = Colors.white;
  Color _gkColor = const Color(0xFFFFC107);
  List<Team> _teams = [];
  int? _selectedLogo;

  final List<String> _logos = List.generate(20, (i) => 'asset/Teams_Logo/${i + 1}.png');

  String _colorToHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Future<void> _pickColor(String title, Color initial, void Function(Color) onChanged) async {
    Color selected = initial;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Pick $title Color',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPri : AppColors.lightTextPri)),
        content: SingleChildScrollView(
          child: HueRingPicker(
            pickerColor: initial,
            onColorChanged: (c) => selected = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done',
                style: GoogleFonts.inter(
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    setState(() => onChanged(selected));
  }

  void _addTeam() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedLogo == null) {
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(
          'Name and logo required.', isError: true));
      return;
    }
    setState(() {
      _teams.add(Team(
        name: name,
        logo: _logos[_selectedLogo!],
        players: [],
        primaryColor: _colorToHex(_primaryColor),
        secondaryColor: _colorToHex(_secondaryColor),
        goalkeeperColor: _colorToHex(_gkColor),
      ));
      _nameController.clear();
      _primaryColor = const Color(0xFF0066FF); // Dark Neon Blue
      _secondaryColor = Colors.white;
      _gkColor = const Color(0xFFFFC107);
      _selectedLogo = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        _snackBar('Team added! You can now add players.'));
  }

  Future<void> _managePlayers(int index) async {
    final updated = await Navigator.push<Team>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePlayersPage(
            team: _teams[index], leagueName: widget.leagueName),
      ),
    );
    if (updated != null) setState(() => _teams[index] = updated);
  }

  void _finalize() {
    if (_teams.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(_snackBar('Please add at least one team.', isError: true));
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMatchPage(
          leagueLogo: widget.logo,
          leagueName: widget.leagueName,
          teams: _teams,
          startDate: widget.startDate,
          endDate: widget.endDate,
        ),
      ),
    );
  }

  SnackBar _snackBar(String msg, {bool isError = false}) => SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: isError ? AppColors.darkError : AppColors.darkPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
        title: Text('Add Teams',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: textPri)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Team Name ───────────────────────────
            _label('TEAM DETAILS', textSec),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: divider),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.shield_outlined, color: primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.inter(fontSize: 14, color: textPri),
                        decoration: InputDecoration(
                          hintText: 'Team Name',
                          hintStyle: GoogleFonts.inter(color: textSec, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Kit Colors ──────────────────────────
            _label('KIT COLORS', textSec),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _colorChip('Primary', _primaryColor, cardBg, divider,
                    () => _pickColor('Primary', _primaryColor, (c) => _primaryColor = c)),
                _colorChip('Secondary', _secondaryColor, cardBg, divider,
                    () => _pickColor('Secondary', _secondaryColor, (c) => _secondaryColor = c)),
                _colorChip('Goalkeeper', _gkColor, cardBg, divider,
                    () => _pickColor('Goalkeeper', _gkColor, (c) => _gkColor = c)),
              ],
            ),

            const SizedBox(height: 20),

            // ── Logo Picker ─────────────────────────
            _label('SELECT TEAM LOGO', textSec),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_logos.length, (i) {
                final isSelected = _selectedLogo == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedLogo = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? primary : divider,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8)]
                          : [],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: cardBg,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(_logos[i]),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // ── Add Team Button ─────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _addTeam,
                icon: const Icon(Icons.group_add_outlined, color: Colors.black),
                label: Text('Add Team',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),

            // ── Teams List ──────────────────────────
            if (_teams.isNotEmpty) ...[
              const SizedBox(height: 28),
              _label('TEAMS IN THIS LEAGUE', textSec),
              const SizedBox(height: 10),
              ..._teams.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: divider),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Image.asset(t.logo, width: 40, height: 40),
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
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _colorDot(t.primaryColor),
                                      const SizedBox(width: 4),
                                      _colorDot(t.secondaryColor),
                                      const SizedBox(width: 4),
                                      _colorDot(t.goalkeeperColor),
                                      const SizedBox(width: 8),
                                      Text('${t.players.length} players',
                                          style: GoogleFonts.inter(
                                              fontSize: 11, color: textSec)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.darkError, size: 20),
                              onPressed: () => setState(() => _teams.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _managePlayers(i),
                            icon: Icon(Icons.person_add_alt_1_outlined,
                                color: primary, size: 18),
                            label: Text(
                              t.players.isEmpty ? 'Add Players' : 'Manage Players',
                              style: GoogleFonts.inter(
                                  color: primary, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primary.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _finalize,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text('Finalize & Create Matches',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkSecondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String t, Color c) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 2),
        child: Text(t,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700, color: c, letterSpacing: 1.2)),
      );

  Widget _colorChip(String label, Color color, Color cardBg, Color divider, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: divider, width: 2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
            ),
            child: const Icon(Icons.colorize, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.darkTextSec)),
        ],
      ),
    );
  }

  Widget _colorDot(String? hexColor) {
    if (hexColor == null) return const SizedBox.shrink();
    try {
      return Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: Color(int.parse(hexColor.replaceAll('#', '0xFF'))),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
