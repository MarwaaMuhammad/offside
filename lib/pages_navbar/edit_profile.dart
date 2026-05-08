import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:offside/models/user_model.dart';
import 'package:offside/services/api_service.dart';
import 'package:offside/theme_provider.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _nationalityController;
  File? _imageFile;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _nationalityController =
        TextEditingController(text: widget.user.nationality);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? f =
          await _picker.pickImage(source: source, imageQuality: 70);
      if (f != null) setState(() => _imageFile = File(f.path));
    } catch (_) {}
  }

  void _showImageSourceSheet(bool isDark, Color primary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
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
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Change Profile Photo',
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
                _pickImage(ImageSource.gallery);
              }),
              _sheetOption(Icons.camera_alt_outlined, 'Camera', primary, isDark,
                  () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
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
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextPri
                        : AppColors.lightTextPri)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      String? imageUrl = widget.user.profileImage;
      if (_imageFile != null) {
        imageUrl = await ApiService.uploadProfileImage(
            _imageFile!, widget.user.id);
      }

      final updates = {
        if (widget.user.role == 'player')
          'full_name': _nameController.text.trim()
        else
          'name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'nationality': _nationalityController.text.trim(),
        if (imageUrl != null) 'profile_image_url': imageUrl,
      };

      await ApiService.updateUserProfile(
        email: widget.user.email,
        role: widget.user.role,
        updates: updates,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white)),
            backgroundColor: AppColors.darkPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes. Please try again.',
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
      if (mounted) setState(() => _isSaving = false);
    }
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
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 18, color: textPri),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPri)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ───────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          _showImageSourceSheet(isDark, primary),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: primary, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 58,
                              backgroundColor: cardBg,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (widget.user.profileImage != null &&
                                          widget.user.profileImage!.isNotEmpty
                                      ? NetworkImage(
                                              widget.user.profileImage!)
                                          as ImageProvider
                                      : null),
                              child: (_imageFile == null &&
                                      (widget.user.profileImage == null ||
                                          widget.user.profileImage!.isEmpty))
                                  ? Icon(Icons.person,
                                      size: 58, color: textSec)
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
                                border: Border.all(color: bg, width: 2),
                              ),
                              child: const Icon(Icons.edit,
                                  size: 16, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Section header ───────────────────
                  Text('Personal Information',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textSec,
                          letterSpacing: 1.2)),

                  const SizedBox(height: 12),

                  // ── Fields ───────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: divider),
                    ),
                    child: Column(
                      children: [
                        _fieldRow(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          primary: primary,
                          textPri: textPri,
                          textSec: textSec,
                          cardBg: cardBg,
                          divider: divider,
                          validator: (v) =>
                              v!.isEmpty ? 'Please enter your name' : null,
                        ),
                        Divider(height: 1, color: divider, indent: 54),
                        _fieldRow(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          primary: primary,
                          textPri: textPri,
                          textSec: textSec,
                          cardBg: cardBg,
                          divider: divider,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.isEmpty
                              ? 'Please enter your phone'
                              : null,
                        ),
                        Divider(height: 1, color: divider, indent: 54),
                        _fieldRow(
                          controller: _nationalityController,
                          label: 'Nationality',
                          icon: Icons.public_outlined,
                          primary: primary,
                          textPri: textPri,
                          textSec: textSec,
                          cardBg: cardBg,
                          divider: divider,
                          validator: (v) => v!.isEmpty
                              ? 'Please enter your nationality'
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Save Button ──────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text('SAVE CHANGES',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: Center(
                child: CircularProgressIndicator(color: primary),
              ),
            ),
        ],
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
    required Color cardBg,
    required Color divider,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
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
                labelText: label,
                labelStyle:
                    GoogleFonts.inter(fontSize: 12, color: textSec),
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
