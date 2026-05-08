import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/pages_details/details_league.dart';
import 'package:offside/services/sync_service.dart';
import 'package:offside/theme_provider.dart';

class CreateMatchPage extends StatefulWidget {
  final List<Team> teams;
  final String leagueLogo;
  final String leagueName;
  final DateTime? startDate;
  final DateTime? endDate;

  const CreateMatchPage({
    super.key,
    required this.teams,
    required this.leagueLogo,
    required this.leagueName,
    this.startDate,
    this.endDate,
  });

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  List<Match2> _matches = [];
  bool _isSyncing = false;

  void _generateSchedule() {
    setState(() {
      _matches.clear();
      final shuffled = List<Team>.from(widget.teams)..shuffle();
      for (int i = 0; i < shuffled.length; i++) {
        for (int j = i + 1; j < shuffled.length; j++) {
          _matches.add(Match2(
            homeTeam: shuffled[i],
            awayTeam: shuffled[j],
            date: widget.startDate ?? DateTime.now(),
          ));
        }
      }
    });
  }

  Future<void> _pickDateTime(int index, Color primary) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _matches[index].date,
      firstDate: widget.startDate ?? DateTime(2020),
      lastDate: widget.endDate ?? DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_matches[index].date),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _matches[index] = Match2(
        homeTeam: _matches[index].homeTeam,
        awayTeam: _matches[index].awayTeam,
        date: DateTime(picked.year, picked.month, picked.day,
            pickedTime.hour, pickedTime.minute),
      );
    });
  }

  Future<void> _saveMatches() async {
    setState(() => _isSyncing = true);
    try {
      final box = await Hive.openBox<League>('leagues');
      final league = League(
        logo: widget.leagueLogo,
        name: widget.leagueName,
        teams: widget.teams,
        matches: _matches,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );
      await box.add(league);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_snackBar('League saved!'));

      await SyncService.syncLeagueToBackend(league);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(_snackBar('Synced to backend successfully!'));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LeaguePage(league: league)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(_snackBar('Sync error. League saved locally.', isError: true));
      final box = Hive.box<League>('leagues');
      if (box.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LeaguePage(league: box.values.last)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPri = isDark ? AppColors.darkTextPri : AppColors.lightTextPri;
    final textSec = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final fmt = DateFormat('dd MMM – HH:mm');

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 18, color: textPri),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.leagueName,
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: textPri)),
        actions: [
          if (_isSyncing)
            Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: primary, strokeWidth: 2),
              ),
            )
          else if (_matches.isNotEmpty)
            IconButton(
              icon: Icon(Icons.cloud_upload_outlined, color: primary),
              onPressed: _saveMatches,
              tooltip: 'Save & Sync',
            ),
        ],
      ),
      body: Column(
        children: [
          // Date range banner
          if (widget.startDate != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, color: primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd MMM').format(widget.startDate!)} → '
                    '${DateFormat('dd MMM yyyy').format(widget.endDate!)}',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600, color: primary),
                  ),
                ],
              ),
            ),

          // Match list
          Expanded(
            child: _matches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_soccer_outlined,
                            size: 64, color: textSec.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('Tap Generate to create the schedule',
                            style: GoogleFonts.inter(fontSize: 14, color: textSec)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _matches.length,
                    itemBuilder: (ctx, i) {
                      final m = _matches[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: divider),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              // Home team
                              Image.asset(m.homeTeam.logo, width: 32, height: 32),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${m.homeTeam.name}  vs  ${m.awayTeam.name}',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textPri),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.access_time_outlined,
                                            size: 12, color: textSec),
                                        const SizedBox(width: 4),
                                        Text(fmt.format(m.date),
                                            style: GoogleFonts.inter(
                                                fontSize: 11, color: textSec)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Image.asset(m.awayTeam.logo, width: 32, height: 32),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(Icons.edit_calendar_outlined,
                                    color: primary, size: 20),
                                onPressed: () => _pickDateTime(i, primary),
                                tooltip: 'Set date & time',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _generateSchedule,
                    icon: const Icon(Icons.auto_awesome, color: Colors.black),
                    label: Text('Generate Round Robin',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                if (_matches.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _saveMatches,
                      icon: Icon(Icons.cloud_upload_outlined,
                          color: isDark ? Colors.black : Colors.white),
                      label: Text('Save & Sync League',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isDark ? Colors.black : Colors.white)),
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
        ],
      ),
    );
  }
}
