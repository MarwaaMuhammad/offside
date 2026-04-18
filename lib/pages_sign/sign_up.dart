import 'package:flutter/material.dart';
import 'package:offside/pages_sign/role_selection.dart';

class SignUpPage extends StatefulWidget {
  final Map<String, String> users;
  const SignUpPage({super.key, required this.users});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String msg_error = "";

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  void _signUp() {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
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

    if (widget.users.containsKey(email)) {
      setState(() => msg_error = "Email already exists");
      return;
    }

    setState(() {
      widget.users[email] = password;
      msg_error = "";
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RoleSelectionPage(userName: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Colors.blue[900]!;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 28, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Image.asset('asset/logo.png', width: 150, height: 150),
              Text(
                "Create your account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
              ),
              const SizedBox(height: 30),
              _buildTextField(nameController, "Full Name", Icons.person, false),
              const SizedBox(height: 16),
              _buildTextField(emailController, "Email Address", Icons.email, false),
              const SizedBox(height: 16),
              _buildTextField(passwordController, "Password", Icons.lock, true),
              const SizedBox(height: 16),
              _buildTextField(confirmPasswordController, "Confirm Password", Icons.lock_outline, true),
              const SizedBox(height: 20),
              if (msg_error.isNotEmpty)
                Text(msg_error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    backgroundColor: primary,
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue[900]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
