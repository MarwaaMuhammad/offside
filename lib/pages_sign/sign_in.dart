import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:offside/navbar.dart';
import 'package:offside/services/api_service.dart';
import 'package:offside/theme_provider.dart';
import 'sign_up.dart';
import 'role_selection.dart';

class SignInPage extends StatefulWidget {
  final Map<String, String> users;
  const SignInPage({super.key, required this.users});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }

    setState(() { _isLoading = true; _error = ''; });

    try {
      debugPrint('🔑 [SignIn] Step 1: Initiating signInWithPassword for $email...');
      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      
      debugPrint('🔑 [SignIn] Step 2: Auth call success. User UID: ${res.user?.id}');

      if (res.user != null && mounted) {
        // Determine role
        String role = 'user';
        String? userName;
        bool hasProfile = false;
        try {
          debugPrint('🔑 [SignIn] Step 3: Fetching user data from ApiService...');
          final data = await ApiService.fetchUserData(email)
              .timeout(const Duration(seconds: 10));
          debugPrint('🔑 [SignIn] Step 4: User data fetch result: $data');
          if (data != null) {
            hasProfile = true;
            role = data['role'] ?? 'user';
            userName = data['full_name'] ?? data['name'];
          }
        } catch (e) {
          debugPrint('⚠️ [SignIn] Error fetching user data (will fall back to default role): $e');
        }

        if (!mounted) return;

        if (!hasProfile) {
          debugPrint('⚠️ [SignIn] No database profile found. Redirecting to RoleSelectionPage...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RoleSelectionPage(
                userName: email.split('@').first,
                email: email,
                phone: '',
                users: widget.users,
              ),
            ),
          );
          return;
        }

        debugPrint('🔑 [SignIn] Step 5: Navigating to OffsideShell with role=$role...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OffsideShell(
              userRole: role,
              userName: userName ?? email,
            ),
          ),
        );
      } else if (mounted) {
        setState(() => _error = 'Sign-in completed but user profile is null.');
      }
    } on AuthException catch (e) {
      debugPrint('❌ [SignIn] AuthException: ${e.message}');
      setState(() => _error = e.message);
    } catch (e, stack) {
      debugPrint('❌ [SignIn] Unexpected error: $e\n$stack');
      setState(() => _error = 'An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Logo
                  Image.asset('asset/logo.png', width: 180, height: 180),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome Back',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textPri,
                    ),
                  ),
                  Text(
                    'Sign in to continue',
                    style: GoogleFonts.inter(fontSize: 14, color: textSec),
                  ),

                  const SizedBox(height: 40),

                  // Email field
                  _inputField(
                    controller: _emailController,
                    hint: 'Email Address',
                    icon: Icons.email_outlined,
                    primary: primary,
                    cardBg: cardBg,
                    textPri: textPri,
                    textSec: textSec,
                    divider: divider,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),

                  const SizedBox(height: 14),

                  // Password field
                  _inputField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    primary: primary,
                    cardBg: cardBg,
                    textPri: textPri,
                    textSec: textSec,
                    divider: divider,
                    obscure: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: textSec,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  // Error message
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
                      child: Text(
                        _error,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.darkError),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Sign In button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2.5))
                          : Text('Sign In',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign Up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: GoogleFonts.inter(
                              fontSize: 14, color: textSec)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  SignUpPage(users: widget.users)),
                        ),
                        child: Text('Sign Up',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: primary,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
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

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color primary,
    required Color cardBg,
    required Color textPri,
    required Color textSec,
    required Color divider,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    Iterable<String>? autofillHints,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: divider),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 15, color: textPri),
        autofillHints: autofillHints,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: textSec, fontSize: 14),
          prefixIcon: Icon(icon, color: primary, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
