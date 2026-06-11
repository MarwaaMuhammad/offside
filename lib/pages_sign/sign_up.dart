import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:offside/pages_sign/role_selection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:offside/theme_provider.dart';

class SignUpPage extends StatefulWidget {
  final Map<String, String> users;
  const SignUpPage({super.key, required this.users});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String msg_error = "";
  bool _isLoading = false;

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  Future<void> _signUp() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => msg_error = "Please fill all fields");
      return;
    }

    if (!isValidEmail(email)) {
      setState(() => msg_error = "Please enter a valid email address");
      return;
    }

    if (password != confirmPassword) {
      setState(() => msg_error = "Passwords do not match");
      return;
    }

    setState(() {
      _isLoading = true;
      msg_error = "";
    });

    try {
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RoleSelectionPage(
              userName: name, 
              email: email, 
              phone: phone,
              users: widget.users,
            )),
          );
        }
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains("rate limit")) {
        setState(() => msg_error = "Rate limit exceeded. Please try again later.");
      } else {
        setState(() => msg_error = e.message);
      }
    } catch (e, stack) {
      debugPrint('❌ Sign-up unexpected error: $e\n$stack');
      setState(() => msg_error = "An unexpected error occurred: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textPri = isDark ? AppColors.darkTextPri : AppColors.lightTextPri;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 24, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 🚀 Added ScrollView to prevent overflow
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              children: [
                Image.asset('asset/logo.png', width: 140, height: 140),
                const SizedBox(height: 10),
                Text(
                  "Create your account",
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: textPri),
                ),
                const SizedBox(height: 30),
                _buildTextField(nameController, "Full Name", Icons.person_outline, false),
                const SizedBox(height: 12),
                _buildTextField(emailController, "Email Address", Icons.email_outlined, false),
                const SizedBox(height: 12),
                _buildTextField(phoneController, "Phone Number", Icons.phone_outlined, false, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField(passwordController, "Password", Icons.lock_outline, true),
                const SizedBox(height: 12),
                _buildTextField(confirmPasswordController, "Confirm Password", Icons.lock_reset_outlined, true),
                
                if (msg_error.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(msg_error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.darkError, fontWeight: FontWeight.bold)),
                ],

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      backgroundColor: primary,
                    ),
                    child: Text(
                      "Continue",
                      style: GoogleFonts.inter(color: isDark ? Colors.black : Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Bottom padding
              ],
            ),
          ),
          if (_isLoading)
            Container(color: Colors.black.withValues(alpha: 0.3), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool obscure, {TextInputType keyboardType = TextInputType.text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
