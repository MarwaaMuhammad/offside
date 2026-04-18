import 'package:flutter/material.dart';
import 'package:offside/navbar.dart';
import 'package:offside/pages_sign/player_info.dart';

class RoleSelectionPage extends StatelessWidget {
  final String userName;
  const RoleSelectionPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final Color primary = Colors.blue[900]!;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome, $userName!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primary),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please select your role to continue",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),
              
              _roleCard(
                context,
                title: "Regular User",
                subtitle: "Follow matches, follow teams, and track stats.",
                icon: Icons.person,
                onTap: () {
                  // Direct navigation for Regular Users
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => OffsideShell(userRole: "user", userName: userName)),
                    (route) => false,
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              _roleCard(
                context,
                title: "Player",
                subtitle: "Join teams, track your personal stats, and play matches.",
                icon: Icons.sports_soccer,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlayerInfoPage(userName: userName)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
          border: Border.all(color: Colors.blue[900]!.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue[900]!.withOpacity(0.1),
              child: Icon(icon, color: Colors.blue[900], size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue[900]),
          ],
        ),
      ),
    );
  }
}
