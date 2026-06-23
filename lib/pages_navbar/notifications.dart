import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:offside/models/invitation_model.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/theme_provider.dart';

class NotificationsPage extends StatefulWidget {
  final String userRole;
  final String? currentUserEmail;

  const NotificationsPage(
      {super.key, required this.userRole, this.currentUserEmail});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _listAnimController;

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textPri = isDark ? AppColors.darkTextPri : AppColors.lightTextPri;
    final textSec = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;

    final invitationsBox = Hive.box<Invitation>('invitations');
    final leaguesBox = Hive.box<League>('leagues');

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded, size: 18, color: textPri),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Notifications',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textPri,
                    ),
                  ),
                  const Spacer(),
                  ValueListenableBuilder(
                    valueListenable: invitationsBox.listenable(),
                    builder: (_, Box<Invitation> box, __) {
                      final pending = box.values
                          .where((i) => i.status == 'pending')
                          .length;
                      if (pending == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pending new',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── List ─────────────────────────────────
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: invitationsBox.listenable(),
                builder: (context, Box<Invitation> box, _) {
                  final all = box.values.toList().reversed.toList();
                  final invitations = widget.userRole == 'player'
                      ? all
                          .where((i) =>
                              i.playerId == widget.currentUserEmail ||
                              i.playerName == widget.currentUserEmail)
                          .toList()
                      : all;

                  if (invitations.isEmpty) {
                    return _emptyState(textSec);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: invitations.length,
                    itemBuilder: (ctx, index) {
                      final invite = invitations[index];
                      return _animatedCard(
                        index: index,
                        child: _notificationCard(
                          invite: invite,
                          isDark: isDark,
                          primary: primary,
                          textPri: textPri,
                          textSec: textSec,
                          leaguesBox: leaguesBox,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedCard({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _listAnimController,
      builder: (_, __) {
        final delay = (index * 0.08).clamp(0.0, 0.8);
        final anim = CurvedAnimation(
          parent: _listAnimController,
          curve: Interval(delay, (delay + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOut),
        );
        return Transform.translate(
          offset: Offset(0, 20 * (1 - anim.value)),
          child: Opacity(opacity: anim.value, child: child),
        );
      },
    );
  }

  Widget _notificationCard({
    required Invitation invite,
    required bool isDark,
    required Color primary,
    required Color textPri,
    required Color textSec,
    required Box<League> leaguesBox,
  }) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final isPending = invite.status == 'pending';
    final isAccepted = invite.status == 'accepted';

    final statusColor = isPending
        ? AppColors.darkAccent
        : isAccepted
            ? AppColors.darkPrimary
            : AppColors.darkError;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? statusColor.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
        // Left accent bar for pending
        boxShadow: isPending
            ? [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 4,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icon
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              widget.userRole == 'player'
                                  ? Icons.group_add_outlined
                                  : Icons.send_outlined,
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userRole == 'player'
                                      ? 'Invitation from ${invite.teamName}'
                                      : 'Invite sent to ${invite.playerName}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textPri,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${invite.leagueName} • Jersey #${invite.jerseyNumber}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: textSec,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _statusBadge(invite.status),
                        ],
                      ),
                      // Accept / Reject buttons for pending player invites
                      if (widget.userRole == 'player' && isPending) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                label: 'Accept',
                                color: AppColors.darkPrimary,
                                onTap: () => _handleResponse(
                                    invite, 'accepted', leaguesBox),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _actionButton(
                                label: 'Decline',
                                color: AppColors.darkError,
                                isOutlined: true,
                                onTap: () => _handleResponse(
                                    invite, 'rejected', leaguesBox),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isAccepted = status == 'accepted';
    final isPending = status == 'pending';
    final color = isPending
        ? AppColors.darkAccent
        : isAccepted
            ? AppColors.darkPrimary
            : AppColors.darkError;
    final label =
        isPending ? 'PENDING' : isAccepted ? 'ACCEPTED' : 'DECLINED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(10),
          border: isOutlined ? Border.all(color: color) : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isOutlined ? color : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(Color textSec) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: textSec.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.inter(fontSize: 15, color: textSec),
          ),
        ],
      ),
    );
  }

  void _handleResponse(
      Invitation invite, String newStatus, Box<League> leaguesBox) {
    setState(() {
      invite.status = newStatus;
      invite.save();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == 'accepted'
              ? 'Invitation accepted!'
              : 'Invitation declined.',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: newStatus == 'accepted'
            ? AppColors.darkPrimary
            : AppColors.darkError,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    if (newStatus == 'accepted') {
      try {
        final league = leaguesBox.values
            .firstWhere((l) => l.name == invite.leagueName);
        final team =
            league.teams.firstWhere((t) => t.name == invite.teamName);
        Player? foundPlayer;
        for (var l in leaguesBox.values) {
          for (var t in l.teams) {
            for (var p in t.players) {
              if (p.name == invite.playerName) {
                foundPlayer = p;
                break;
              }
            }
          }
        }
        if (foundPlayer != null) {
          team.players.add(Player(
            name: foundPlayer.name,
            position: foundPlayer.position,
            age: foundPlayer.age,
            nationality: foundPlayer.nationality,
            number: invite.jerseyNumber,
            height: foundPlayer.height,
            weight: foundPlayer.weight,
          ));
          league.save();
        }
      } catch (_) {}
    }
  }
}
