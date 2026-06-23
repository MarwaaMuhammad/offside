import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:offside/pages_navbar/analysis.dart';
import 'package:offside/pages_navbar/matchs.dart';
import 'package:offside/pages_navbar/players.dart';
import 'package:offside/pages_navbar/profile.dart';
import 'package:offside/pages_add/add_league.dart';
import 'package:offside/theme_provider.dart';

class OffsideShell extends StatefulWidget {
  final String userRole; // "user" or "player"
  final String? userName;
  const OffsideShell({super.key, this.userRole = "user", this.userName});

  @override
  State<OffsideShell> createState() => _OffsideShellState();
}

class _OffsideShellState extends State<OffsideShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late List<Widget> _pages;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _pages = [
      MatchesPage(userRole: widget.userRole, userName: widget.userName),
      AnalysisPage(userRole: widget.userRole),
      const PlayersPage(),
      const ProfilePage(),
    ];
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (_index == index) return;
    _animController.forward(from: 0);
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _buildNavBar(isDark),
    );
  }

  Widget _buildNavBar(bool isDark) {
    final navBg = isDark ? AppColors.darkNavBar : Colors.white;
    final items = [
      _NavItem(
          index: 0,
          label: 'Matches',
          icon: 'asset/icons/guidance_stadium.svg',
          isSvg: true),
      _NavItem(
          index: 1,
          label: 'Analysis',
          icon: 'asset/icons/analysis.svg',
          isSvg: true),
      if (widget.userRole != 'player')
        _NavItem(
            index: -1,
            label: 'Create Team',
            icon: '',
            isSvg: false,
            materialIcon: Icons.add,
            materialIconActive: Icons.add,
            isAction: true),
      _NavItem(
          index: 2,
          label: 'Players',
          icon: 'asset/icons/play-football.svg',
          isSvg: true),
      _NavItem(
          index: 3,
          label: widget.userRole == 'player' ? 'My Profile' : 'Profile',
          icon: 'asset/icons/profile.svg',
          isSvg: true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) => _buildTab(item, isDark)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(_NavItem item, bool isDark) {
    final isSelected = !item.isAction && _index == item.index;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inactive = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;

    return GestureDetector(
      onTap: () {
        if (item.isAction) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateLeaguePage()),
          );
        } else {
          _onTabTap(item.index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glow effect for active
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ],
                ),
              )
            else
              const SizedBox(height: 8),
            // Icon
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: item.isSvg
                  ? SvgPicture.asset(
                      item.icon,
                      // ignore: deprecated_member_use
                      color: isSelected ? primary : inactive,
                      width: 22,
                      height: 22,
                    )
                  : Icon(
                      isSelected
                          ? item.materialIconActive
                          : item.materialIcon,
                      color: item.isAction ? primary : (isSelected ? primary : inactive),
                      size: 22,
                    ),
            ),
            const SizedBox(height: 4),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: item.isAction ? primary : (isSelected ? primary : inactive),
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final int index;
  final String label;
  final String icon;
  final bool isSvg;
  final IconData? materialIcon;
  final IconData? materialIconActive;
  final bool isAction;

  _NavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.isSvg,
    this.materialIcon,
    this.materialIconActive,
    this.isAction = false,
  });
}
