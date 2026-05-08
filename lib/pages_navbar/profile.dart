import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/user_model.dart';
import 'package:offside/pages_sign/sign_in.dart';
import 'package:offside/services/api_service.dart';
import 'package:offside/theme_provider.dart';
import 'package:offside/pages_navbar/my_leagues.dart';
import 'package:offside/pages_navbar/edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _userModel;
  bool _isLoading = true;
  String? _error;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        final data = await ApiService.fetchUserData(user.email!);
        if (data != null) {
          setState(() {
            _userModel = UserModel.fromJson(data, data['role']);
          });
        } else {
          setState(() => _error = 'Could not load profile. Please try again.');
        }
      } else {
        setState(() => _error = 'Not signed in.');
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _error = 'Failed to load profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image =
          await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null && _userModel != null) {
        setState(() => _isLoading = true);
        final imageUrl = await ApiService.uploadProfileImage(
            File(image.path), _userModel!.id);
        await ApiService.updateUserProfile(
          email: _userModel!.email,
          role: _userModel!.role,
          updates: {'profile_image_url': imageUrl},
        );
        await _loadUserProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _styledSnackBar(
              'Failed to upload image. Please try again.', isError: true),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageSourceActionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
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
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Change Profile Photo',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPri : AppColors.lightTextPri)),
              const SizedBox(height: 8),
              _bottomSheetOption(
                context,
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
                isDark: isDark,
              ),
              _bottomSheetOption(
                context,
                icon: Icons.camera_alt_outlined,
                label: 'Take a Photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomSheetOption(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      required bool isDark}) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
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
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primary, size: 20),
            ),
            const SizedBox(width: 16),
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextPri : AppColors.lightTextPri,
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    if (_userModel == null) return;
    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => EditProfilePage(user: _userModel!)),
    );
    if (result == true) _loadUserProfile();
  }

  Future<void> clearCache() async {
    final box = await Hive.openBox<League>('leagues');
    await box.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(_styledSnackBar('Cache cleared successfully!'));
    setState(() {});
  }

  void _signOut() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.inter(
                color: isDark ? AppColors.darkTextSec : AppColors.lightTextSec)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: isDark ? AppColors.darkTextSec : AppColors.lightTextSec)),
          ),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInPage(users: {})),
                  (route) => false,
                );
              }
            },
            child: Text('Sign Out',
                style: GoogleFonts.inter(
                    color: AppColors.darkError, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  SnackBar _styledSnackBar(String msg, {bool isError = false}) {
    return SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor:
          isError ? AppColors.darkError : AppColors.darkPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(color: primary),
        ),
      );
    }

    if (_error != null && _userModel == null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.darkError),
                const SizedBox(height: 16),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 15, color: textSec)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadUserProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: primary,
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Hero Header ────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.darkCard,
                            AppColors.darkBg,
                          ]
                        : [
                            primary.withOpacity(0.08),
                            AppColors.lightBg,
                          ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Column(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _showImageSourceActionSheet,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: primary, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          primary.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 54,
                                  backgroundColor: cardBg,
                                  backgroundImage: (_userModel
                                              ?.profileImage !=
                                          null &&
                                      _userModel!
                                          .profileImage!.isNotEmpty)
                                      ? NetworkImage(
                                          _userModel!.profileImage!)
                                      : null,
                                  child: (_userModel?.profileImage ==
                                              null ||
                                          _userModel!
                                              .profileImage!.isEmpty)
                                      ? Icon(Icons.person,
                                          size: 54,
                                          color: textSec)
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: bg, width: 2),
                                  ),
                                  child: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userModel?.name ?? 'User',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPri,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userModel?.email ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: textSec),
                        ),
                        const SizedBox(height: 10),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            (_userModel?.role ?? '').toUpperCase(),
                            style: GoogleFonts.inter(
                              color: primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Edit Profile Button
                        SizedBox(
                          width: 180,
                          child: ElevatedButton(
                            onPressed: _userModel != null
                                ? _navigateToEditProfile
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Edit Profile',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Info Section ────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('User Information', textSec),
                    _infoCard(cardBg, divider, [
                      _infoRow(Icons.person_outline, 'Name',
                          _userModel?.name ?? 'N/A', primary, textPri, textSec),
                      _divider(divider),
                      _infoRow(Icons.email_outlined, 'Email',
                          _userModel?.email ?? 'N/A', primary, textPri, textSec),
                      _divider(divider),
                      _infoRow(
                          Icons.phone_outlined,
                          'Phone',
                          (_userModel?.phoneNumber.isNotEmpty ?? false)
                              ? _userModel!.phoneNumber
                              : 'N/A',
                          primary,
                          textPri,
                          textSec),
                      _divider(divider),
                      _infoRow(
                          Icons.public_outlined,
                          'Nationality',
                          (_userModel?.nationality.isNotEmpty ?? false)
                              ? _userModel!.nationality
                              : 'N/A',
                          primary,
                          textPri,
                          textSec),
                    ]),

                    const SizedBox(height: 20),

                    _sectionTitle('Settings', textSec),
                    _settingsCard(cardBg, divider, isDark, primary, textPri, textSec),

                    const SizedBox(height: 20),

                    _sectionTitle('Account', textSec),
                    _actionTile(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      color: AppColors.darkError,
                      cardBg: cardBg,
                      textPri: AppColors.darkError,
                      onTap: _signOut,
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color textSec) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textSec,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _infoCard(Color cardBg, Color divider, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(Color color) =>
      Divider(height: 1, color: color, indent: 54);

  Widget _infoRow(IconData icon, String label, String value, Color primary,
      Color textPri, Color textSec) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primary, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: textSec)),
              Text(value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPri,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(Color cardBg, Color divider, bool isDark,
      Color primary, Color textPri, Color textSec) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider),
      ),
      child: Column(
        children: [
          _settingsTile(
            icon: Icons.sports_soccer_outlined,
            label: 'My Leagues',
            primary: primary,
            textPri: textPri,
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => const MyLeaguesPage()),
            ),
          ),
          Divider(height: 1, color: divider, indent: 54),
          // Dark mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                      color: primary, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Dark Mode',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPri)),
                ),
                Switch.adaptive(
                  value: isDark,
                  activeColor: primary,
                  onChanged: (_) => ThemeProvider.toggleTheme(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: divider, indent: 54),
          _settingsTile(
            icon: Icons.delete_sweep_outlined,
            label: 'Clear Cache',
            primary: primary,
            textPri: textPri,
            onTap: clearCache,
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required Color primary,
    required Color textPri,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPri,
                  )),
            ),
            Icon(Icons.chevron_right,
                size: 18,
                color: textPri.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required Color cardBg,
    required Color textPri,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
