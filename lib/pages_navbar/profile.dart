import 'dart:io';
import 'package:flutter/material.dart';
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
      setState(() => _error = 'Failed to load profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null && _userModel != null) {
        setState(() => _isLoading = true);
        final imageUrl = await ApiService.uploadProfileImage(File(image.path), _userModel!.id);
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
          const SnackBar(
            content: Text('Failed to upload image. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    if (_userModel == null) return;
    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => EditProfilePage(user: _userModel!),
      ),
    );
    if (result == true) {
      _loadUserProfile();
    }
  }

  Future<void> clearCache() async {
    final box = await Hive.openBox<League>('leagues');
    await box.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Cache cleared successfully!'),
      duration: Duration(seconds: 2),
    ));
    setState(() {});
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    // Loading state
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (_error != null && _userModel == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ── Profile Avatar ──────────────────────────────────────────
              GestureDetector(
                onTap: _showImageSourceActionSheet,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: primary,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: (_userModel?.profileImage != null &&
                                _userModel!.profileImage!.isNotEmpty)
                            ? NetworkImage(_userModel!.profileImage!)
                            : null,
                        child: (_userModel?.profileImage == null ||
                                _userModel!.profileImage!.isEmpty)
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: primary,
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Name ────────────────────────────────────────────────────
              Text(
                _userModel?.name ?? 'User',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),

              // ── Email ───────────────────────────────────────────────────
              Text(
                _userModel?.email ?? '',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),

              // ── Role badge ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _userModel?.role.toUpperCase() ?? '',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Edit Profile button ─────────────────────────────────────
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: _userModel != null ? _navigateToEditProfile : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Edit Profile', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 25),

              // ── User Information ────────────────────────────────────────
              sectionHeader('User Information'),
              _infoTile(Icons.person, 'Name', _userModel?.name ?? 'N/A'),
              _infoTile(Icons.email, 'Email', _userModel?.email ?? 'N/A'),
              _infoTile(
                Icons.phone,
                'Phone',
                (_userModel?.phoneNumber.isNotEmpty ?? false)
                    ? _userModel!.phoneNumber
                    : 'N/A',
              ),
              _infoTile(
                Icons.public,
                'Nationality',
                (_userModel?.nationality.isNotEmpty ?? false)
                    ? _userModel!.nationality
                    : 'N/A',
              ),

              const SizedBox(height: 25),

              // ── Settings ────────────────────────────────────────────────
              sectionHeader('Settings'),
              settingTile(Icons.sports_soccer, 'My Leagues', () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const MyLeaguesPage()),
                );
              }),

              // Dark Mode toggle
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  secondary: Icon(
                    Icons.dark_mode,
                    color: isDark ? Colors.blueAccent : const Color(0xFF16246E),
                  ),
                  title: const Text('Dark Mode', style: TextStyle(fontSize: 16)),
                  value: isDark,
                  onChanged: (_) => ThemeProvider.toggleTheme(),
                ),
              ),

              settingTile(Icons.delete_forever, 'Clear Cache', clearCache),

              const SizedBox(height: 30),

              // ── Account ─────────────────────────────────────────────────
              sectionHeader('Account'),
              settingTile(Icons.logout, 'Sign Out', _signOut, isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionHeader(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDark ? Colors.blueAccent : const Color(0xFF16246E),
        ),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget settingTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Theme.of(context).cardTheme.color,
        leading: Icon(
          icon,
          color: isDestructive
              ? Colors.red
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.blueAccent
                  : const Color(0xFF16246E)),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 16, color: isDestructive ? Colors.red : null),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
