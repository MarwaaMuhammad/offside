import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:offside/pages_add/add_team.dart';
import 'package:offside/theme_provider.dart';

class CreateLeaguePage extends StatefulWidget {
  const CreateLeaguePage({super.key});

  @override
  State<CreateLeaguePage> createState() => _CreateLeaguePageState();
}

class _CreateLeaguePageState extends State<CreateLeaguePage> {
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedLogo;

  final List<String> _logos = List.generate(8, (i) => 'asset/leagues_logo/${i + 1}.png');

  Future<void> _pickDate(bool isStart) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  void _next() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedLogo == null || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(_snackBar(
        'Please fill all fields and select dates.',
        isError: true,
      ));
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTeamPage(
          leagueName: name,
          logo: _logos[_selectedLogo!],
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
  }

  SnackBar _snackBar(String msg, {bool isError = false}) => SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: Colors.white)),
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
        title: Text('Create League',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: textPri)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // League Name
            _label('LEAGUE DETAILS', textSec),
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
                      child: Icon(Icons.emoji_events_outlined, color: primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.inter(fontSize: 14, color: textPri),
                        decoration: InputDecoration(
                          hintText: 'League Name',
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

            // Date range
            _label('TOURNAMENT DATES', textSec),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _datePicker(
                  label: _startDate == null ? 'Start Date' : DateFormat('dd MMM yyyy').format(_startDate!),
                  icon: Icons.play_circle_outline,
                  onTap: () => _pickDate(true),
                  primary: primary, cardBg: cardBg, textPri: textPri, textSec: textSec, divider: divider,
                  isSet: _startDate != null,
                )),
                const SizedBox(width: 12),
                Expanded(child: _datePicker(
                  label: _endDate == null ? 'End Date' : DateFormat('dd MMM yyyy').format(_endDate!),
                  icon: Icons.stop_circle_outlined,
                  onTap: () => _pickDate(false),
                  primary: primary, cardBg: cardBg, textPri: textPri, textSec: textSec, divider: divider,
                  isSet: _endDate != null,
                )),
              ],
            ),

            const SizedBox(height: 24),

            // Logo picker
            _label('SELECT LEAGUE LOGO', textSec),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_logos.length, (i) {
                final isSelected = _selectedLogo == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedLogo = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? primary : divider,
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 10)]
                          : [],
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: cardBg,
                      backgroundImage: AssetImage(_logos[i]),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _next,
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                label: Text('Next: Add Teams',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, Color textSec) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 2),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: textSec, letterSpacing: 1.2)),
      );

  Widget _datePicker({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color primary,
    required Color cardBg,
    required Color textPri,
    required Color textSec,
    required Color divider,
    required bool isSet,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSet ? primary.withValues(alpha: 0.5) : divider),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSet ? primary : textSec),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isSet ? textPri : textSec,
                        fontWeight: isSet ? FontWeight.w600 : FontWeight.w400),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      );
}
