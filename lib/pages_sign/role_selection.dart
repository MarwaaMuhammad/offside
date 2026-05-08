import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:offside/pages_sign/player_info.dart';
import 'package:offside/pages_sign/sign_in.dart';
import 'package:offside/services/api_service.dart';
import 'package:offside/theme_provider.dart';

class RoleSelectionPage extends StatefulWidget {
  final String userName;
  final String? email;
  final String? phone;
  final Map<String, String> users;
  const RoleSelectionPage(
      {super.key,
      required this.userName,
      this.email,
      this.phone,
      required this.users});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _isLoading = false;

  Future<void> _handleRegularUser() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.createUser(
        name: widget.userName,
        email: widget.email ??
            'user_${DateTime.now().millisecondsSinceEpoch}@example.com',
        nationality: 'Unknown',
        phoneNumber: widget.phone ?? '0000000000',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created! Please sign in.',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create account. Please try again.',
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final secondary = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPri = isDark ? AppColors.darkTextPri : AppColors.lightTextPri;
    final textSec = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.sports_soccer, color: primary, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome, ${widget.userName}!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textPri),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to use Offside',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: textSec),
                  ),

                  const SizedBox(height: 40),

                  // Regular User card
                  _roleCard(
                    title: 'Regular User',
                    subtitle: 'Follow matches, leagues, and track team stats.',
                    icon: Icons.person_outline,
                    color: secondary,
                    cardBg: cardBg,
                    divider: divider,
                    textPri: textPri,
                    textSec: textSec,
                    onTap: _handleRegularUser,
                  ),

                  const SizedBox(height: 16),

                  // Player card
                  _roleCard(
                    title: 'Player',
                    subtitle:
                        'Join teams, track personal stats, and play matches.',
                    icon: Icons.sports_soccer_outlined,
                    color: primary,
                    cardBg: cardBg,
                    divider: divider,
                    textPri: textPri,
                    textSec: textSec,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerInfoPage(
                          userName: widget.userName,
                          email: widget.email,
                          phone: widget.phone,
                          users: widget.users,
                        ),
                      ),
                    ),
                  ),
                ],
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

  Widget _roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color divider,
    required Color textPri,
    required Color textSec,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: divider),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPri)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: textSec)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
