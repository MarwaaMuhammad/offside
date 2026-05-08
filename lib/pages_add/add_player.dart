import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/services/api_service.dart';
import 'package:offside/theme_provider.dart';

class CreatePlayersPage extends StatefulWidget {
  final Team team;
  final String leagueName;
  const CreatePlayersPage(
      {super.key, required this.team, required this.leagueName});

  @override
  State<CreatePlayersPage> createState() => _CreatePlayersPageState();
}

class _CreatePlayersPageState extends State<CreatePlayersPage> {
  final _searchController = TextEditingController();
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  Map<String, int> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final players = await ApiService.getAllPlayers();
      setState(() {
        _all = players;
        _filtered = players;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_snackBar(
            'Failed to fetch players.', isError: true));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String q) {
    setState(() {
      _filtered = _all.where((p) {
        final name = (p['full_name'] ?? '').toString().toLowerCase();
        final email = (p['email'] ?? '').toString().toLowerCase();
        return name.contains(q.toLowerCase()) || email.contains(q.toLowerCase());
      }).toList();
    });
  }

  String _pid(Map<String, dynamic> p) =>
      (p['player_id'] ?? p['id'] ?? '').toString();

  void _showJerseyDialog(Map<String, dynamic> player, Color primary, Color cardBg,
      Color textPri, Color textSec) {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Assign Jersey',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textPri)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Assign jersey number for\n${player['full_name']}',
                style: GoogleFonts.inter(fontSize: 13, color: textSec),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
              ),
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w800, color: textPri),
                decoration: InputDecoration(
                  hintText: '#',
                  hintStyle: GoogleFonts.inter(color: textSec, fontSize: 24),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: textSec)),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() => _selected[_pid(player)] = int.parse(ctrl.text));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Assign',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirm() {
    for (final entry in _selected.entries) {
      final pm = _all.firstWhere((p) => _pid(p) == entry.key, orElse: () => {});
      if (pm.isNotEmpty) {
        final np = Player(
          name: pm['full_name'] ?? 'Unknown',
          position: pm['position'] ?? 'Unknown',
          age: pm['age'] ?? 20,
          nationality: pm['nationality'] ?? 'Unknown',
          number: entry.value,
          height: (pm['height'] as num?)?.toDouble(),
          weight: (pm['weight'] as num?)?.toDouble(),
          backendId: entry.key,
        );
        if (!widget.team.players.any((p) => p.backendId == np.backendId)) {
          widget.team.players.add(np);
        }
      }
    }
    Navigator.pop(context, widget.team);
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
    _searchController.dispose();
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
        title: Text('Add Players',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: textPri)),
        actions: [
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_selected.length} selected',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700, color: primary)),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: divider),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _search,
                    style: GoogleFonts.inter(fontSize: 14, color: textPri),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search registered players…',
                      hintStyle: GoogleFonts.inter(color: textSec, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: textSec, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // List
              Expanded(
                child: _filtered.isEmpty && !_loading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined,
                                size: 64, color: textSec.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text('No players found',
                                style:
                                    GoogleFonts.inter(fontSize: 14, color: textSec)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final p = _filtered[i] as Map<String, dynamic>;
                          final id = _pid(p);
                          final isSelected = _selected.containsKey(id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? primary.withValues(alpha: 0.6)
                                    : divider,
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                          color: primary.withValues(alpha: 0.1),
                                          blurRadius: 8)
                                    ]
                                  : [],
                            ),
                            child: InkWell(
                              onTap: () => isSelected
                                  ? setState(() => _selected.remove(id))
                                  : _showJerseyDialog(
                                      p, primary, cardBg, textPri, textSec),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: isSelected
                                                ? primary
                                                : primary.withValues(alpha: 0.3)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (p['full_name'] ?? '?')[0].toUpperCase(),
                                          style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: primary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['full_name'] ?? 'Unknown',
                                              style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPri)),
                                          const SizedBox(height: 2),
                                          Text(
                                            isSelected
                                                ? 'Jersey #${_selected[id]}'
                                                : '${p['position'] ?? 'N/A'} • ${p['nationality'] ?? ''}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: isSelected ? primary : textSec,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.add_circle_outline_rounded,
                                      color: isSelected ? primary : textSec,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Confirm button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selected.isEmpty ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      disabledBackgroundColor: primary.withValues(alpha: 0.3),
                    ),
                    child: Text(
                      _selected.isEmpty
                          ? 'Select Players to Add'
                          : 'Add ${_selected.length} Player${_selected.length > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: Center(child: CircularProgressIndicator(color: primary)),
            ),
        ],
      ),
    );
  }
}
