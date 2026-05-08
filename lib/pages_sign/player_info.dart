import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:offside/pages_sign/sign_in.dart';
import 'package:offside/services/api_service.dart';
import 'package:offside/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerInfoPage extends StatefulWidget {
  final String userName;
  final String? email;
  final String? phone;
  final Map<String, String> users;
  const PlayerInfoPage(
      {super.key,
      required this.userName,
      this.email,
      this.phone,
      required this.users});

  @override
  State<PlayerInfoPage> createState() => _PlayerInfoPageState();
}

class _PlayerInfoPageState extends State<PlayerInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nationalityController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _selectedDob;
  String _selectedPosition = 'Forward';
  bool _isLoading = false;

  final List<String> _positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward'
  ];

  Future<void> _selectDate(Color primary) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select your date of birth.',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, color: Colors.white)),
          backgroundColor: AppColors.darkError,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Session expired.');

      await ApiService.createPlayer(
        fullName: widget.userName,
        jerseyNumber: 0,
        nationality: _nationalityController.text.trim(),
        height: double.tryParse(_heightController.text) ?? 0.0,
        weight: double.tryParse(_weightController.text) ?? 0.0,
        position: _selectedPosition,
        email: widget.email ?? user.email ?? 'no-email@example.com',
        phoneNumber: widget.phone ?? '0000000000',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Player profile created! Please sign in.',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white)),
            backgroundColor: AppColors.darkPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => SignInPage(users: widget.users)),
          (route) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile. Please try again.',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white)),
            backgroundColor: AppColors.darkError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nationalityController.dispose();
    _heightController.dispose();
    _weightController.dispose();
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
        title: Text('Player Details',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPri)),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Complete your player profile',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textSec,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 16),

                    // Fields card
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: divider),
                      ),
                      child: Column(
                        children: [
                          // Date of Birth
                          InkWell(
                            onTap: () => _selectDate(primary),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.calendar_today_outlined,
                                        color: primary, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDob == null
                                        ? 'Date of Birth'
                                        : DateFormat('dd MMM yyyy')
                                            .format(_selectedDob!),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: _selectedDob == null
                                          ? textSec
                                          : textPri,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(height: 1, color: divider, indent: 54),
                          _fieldRow(
                            controller: _nationalityController,
                            label: 'Nationality',
                            icon: Icons.flag_outlined,
                            primary: primary, textPri: textPri,
                            textSec: textSec, divider: divider,
                            validator: (v) =>
                                v!.isEmpty ? 'Enter nationality' : null,
                          ),
                          Divider(height: 1, color: divider, indent: 54),
                          Row(
                            children: [
                              Expanded(
                                child: _fieldRow(
                                  controller: _heightController,
                                  label: 'Height (cm)',
                                  icon: Icons.height,
                                  primary: primary, textPri: textPri,
                                  textSec: textSec, divider: divider,
                                  keyboardType: TextInputType.number,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Enter height' : null,
                                ),
                              ),
                              Container(
                                  width: 1,
                                  height: 52,
                                  color: divider),
                              Expanded(
                                child: _fieldRow(
                                  controller: _weightController,
                                  label: 'Weight (kg)',
                                  icon: Icons.monitor_weight_outlined,
                                  primary: primary, textPri: textPri,
                                  textSec: textSec, divider: divider,
                                  keyboardType: TextInputType.number,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Enter weight' : null,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 1, color: divider, indent: 54),
                          // Position dropdown
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.sports_soccer_outlined,
                                      color: primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedPosition,
                                      dropdownColor: cardBg,
                                      style: GoogleFonts.inter(
                                          fontSize: 14, color: textPri),
                                      icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: textSec),
                                      items: _positions
                                          .map((p) => DropdownMenuItem(
                                                value: p,
                                                child: Text(p,
                                                    style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        color: textPri)),
                                              ))
                                          .toList(),
                                      onChanged: (v) => setState(
                                          () => _selectedPosition = v!),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.black, strokeWidth: 2.5))
                            : Text('Complete Sign Up',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                    child: CircularProgressIndicator(color: primary)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primary,
    required Color textPri,
    required Color textSec,
    required Color divider,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: GoogleFonts.inter(fontSize: 14, color: textPri),
              decoration: InputDecoration(
                hintText: label,
                hintStyle:
                    GoogleFonts.inter(color: textSec, fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
