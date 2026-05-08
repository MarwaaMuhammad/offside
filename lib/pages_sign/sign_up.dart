import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:offside/pages_sign/role_selection.dart';
import 'package:offside/theme_provider.dart';

class SignUpPage extends StatefulWidget {
  final Map<String, String> users;
  const SignUpPage({super.key, required this.users});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _error = '';
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  bool _isValidEmail(String e) =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(e);

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if ([name, email, phone, pass, confirm].any((f) => f.isEmpty)) {
      setState(() => _error = 'Please fill all fields.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _isLoading = true; _error = ''; });

    try {
      final AuthResponse res =
          await Supabase.instance.client.auth.signUp(email: email, password: pass);
      if (res.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoleSelectionPage(
              userName: name,
              email: email,
              phone: phone,
              users: widget.users,
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message.contains('rate limit') || e.message.contains('already registered')
          ? 'This email is already registered. Please sign in.'
          : e.message);
    } catch (_) {
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset('asset/logo.png', width: 100, height: 100),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('Create Account',
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textPri)),
                  ),
                  Center(
                    child: Text('Join the Offside community',
                        style: GoogleFonts.inter(fontSize: 13, color: textSec)),
                  ),
                  const SizedBox(height: 28),

                  // Fields card
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: divider),
                    ),
                    child: Column(
                      children: [
                        _fieldRow(_nameController, 'Full Name',
                            Icons.person_outline, primary, textPri, textSec, divider),
                        Divider(height: 1, color: divider, indent: 54),
                        _fieldRow(_emailController, 'Email Address',
                            Icons.email_outlined, primary, textPri, textSec, divider,
                            keyboardType: TextInputType.emailAddress),
                        Divider(height: 1, color: divider, indent: 54),
                        _fieldRow(_phoneController, 'Phone Number',
                            Icons.phone_outlined, primary, textPri, textSec, divider,
                            keyboardType: TextInputType.phone),
                        Divider(height: 1, color: divider, indent: 54),
                        _fieldRow(_passwordController, 'Password',
                            Icons.lock_outline, primary, textPri, textSec, divider,
                            obscure: _obscurePass,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: textSec, size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            )),
                        Divider(height: 1, color: divider, indent: 54),
                        _fieldRow(_confirmController, 'Confirm Password',
                            Icons.lock_outline, primary, textPri, textSec, divider,
                            obscure: _obscureConfirm,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: textSec, size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureConfirm = !_obscureConfirm),
                            )),
                      ],
                    ),
                  ),

                  // Error
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.darkError.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.darkError.withValues(alpha: 0.3)),
                      ),
                      child: Text(_error,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.darkError)),
                    ),
                  ],

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
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
                          : Text('Create Account',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
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

  Widget _fieldRow(
    TextEditingController controller,
    String hint,
    IconData icon,
    Color primary,
    Color textPri,
    Color textSec,
    Color divider, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
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
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              style: GoogleFonts.inter(fontSize: 14, color: textPri),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(color: textSec, fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                suffixIcon: suffix,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
