import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:offside/models/event_model.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/match_stats_model.dart';
import 'package:offside/models/player_stats_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/pages_details/details_player.dart';
import 'package:offside/pages_details/details_team.dart';
import 'package:offside/theme_provider.dart';

class MatchDetailsPage extends StatefulWidget {
  final Match2 match;
  final League league;

  const MatchDetailsPage({super.key, required this.match, required this.league});

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedTeamIndex = 0; // 0 = Home, 1 = Away

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
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
    const darkBlueBg = Color(0xFF001F24); // Neon blue tinted dark background

    final now = DateTime.now();
    final isUpcoming = now.isBefore(widget.match.date);
    final isLive = now.isAfter(widget.match.date) &&
        now.isBefore(widget.match.date.add(const Duration(minutes: 105)));

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? darkBlueBg : primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [darkBlueBg, AppColors.darkBg]
                        : [primary, primary.withValues(alpha: 0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _teamHero(widget.match.homeTeam, widget.league),
                        // Score / time center
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('● LIVE',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: primary,
                                        letterSpacing: 0.5)),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              isUpcoming
                                  ? DateFormat('HH:mm').format(widget.match.date)
                                  : '${widget.match.homeTeamScore}  –  ${widget.match.awayTeamScore}',
                              style: GoogleFonts.inter(
                                fontSize: isUpcoming ? 22 : 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isUpcoming
                                  ? DateFormat('dd MMM yyyy')
                                      .format(widget.match.date)
                                  : (isLive
                                      ? ''
                                      : widget.match.status ?? 'Full Time'),
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                        _teamHero(widget.match.awayTeam, widget.league),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              labelStyle:
                  GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Timeline'),
                Tab(text: 'Team Stats'),
                Tab(text: 'Players'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _timelineTab(isUpcoming, isDark, primary, cardBg, textPri, textSec, divider),
            _teamStatsTab(isDark, primary, cardBg, textPri, textSec, divider),
            _playerStatsTab(isDark, primary, cardBg, textPri, textSec, divider),
          ],
        ),
      ),
    );
  }

  Widget _teamHero(Team team, League league) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TeamDetailsPage(team: team, league: league)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                team.logo,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.shield, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              child: Text(
                team.name,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _timelineTab(bool isUpcoming, bool isDark, Color primary, Color cardBg,
      Color textPri, Color textSec, Color divider) {
    if (isUpcoming) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.sports_soccer_outlined, color: primary, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Kick-off',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: textSec)),
                  Text(
                    DateFormat('EEEE, dd MMM yyyy').format(widget.match.date),
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPri),
                  ),
                  Text(
                    DateFormat('HH:mm').format(widget.match.date),
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (widget.match.eventsHome.isEmpty && widget.match.eventsAway.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined,
                size: 64, color: textSec.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No events recorded',
                style: GoogleFonts.inter(fontSize: 14, color: textSec)),
          ],
        ),
      );
    }

    final homeEvents = widget.match.eventsHome
        .map((e) => (isHome: true, event: e))
        .toList();
    final awayEvents = widget.match.eventsAway
        .map((e) => (isHome: false, event: e))
        .toList();
    final allEvents = [...homeEvents, ...awayEvents]
      ..sort((a, b) => a.event.minute.compareTo(b.event.minute));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: allEvents.length,
      itemBuilder: (_, i) {
        final entry = allEvents[i];
        return _eventRow(entry.event, entry.isHome, primary, cardBg, textPri,
            textSec, divider);
      },
    );
  }

  Widget _eventRow(Event event, bool isHome, Color primary, Color cardBg,
      Color textPri, Color textSec, Color divider) {
    IconData icon;
    Color iconColor;
    switch (event.type) {
      case 'Goal':
        icon = Icons.sports_soccer;
        iconColor = primary;
        break;
      case 'Yellow Card':
        icon = Icons.square_rounded;
        iconColor = const Color(0xFFFFC107);
        break;
      case 'Red Card':
        icon = Icons.square_rounded;
        iconColor = AppColors.darkError;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = textSec;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: isHome
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(event.player,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPri),
                            textAlign: TextAlign.end),
                      ),
                      const SizedBox(width: 8),
                      Icon(icon, color: iconColor, size: 18),
                    ],
                  )
                : const SizedBox(),
          ),
          Container(
            width: 46,
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text("${event.minute}'",
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primary)),
          ),
          Expanded(
            child: !isHome
                ? Row(
                    children: [
                      Icon(icon, color: iconColor, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(event.player,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPri)),
                      ),
                    ],
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _teamStatsTab(bool isDark, Color primary, Color cardBg, Color textPri,
      Color textSec, Color divider) {
    final box = Hive.box<MatchStats>('match_stats');
    final home = box.values
        .where((s) =>
            s.matchId == widget.match.backendId &&
            s.teamId == widget.match.homeTeam.backendId)
        .firstOrNull;
    final away = box.values
        .where((s) =>
            s.matchId == widget.match.backendId &&
            s.teamId == widget.match.awayTeam.backendId)
        .firstOrNull;

    if (home == null && away == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 64, color: textSec.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No team stats available',
                style: GoogleFonts.inter(fontSize: 14, color: textSec)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        _statBar('Possession %', home?.acquisitionAvg ?? 0,
            away?.acquisitionAvg ?? 0, primary, textPri, textSec, cardBg, divider),
        _statBar('Goals', (home?.goalCount ?? 0).toDouble(),
            (away?.goalCount ?? 0).toDouble(), primary, textPri, textSec, cardBg, divider),
        _statBar('Passes', (home?.passesCount ?? 0).toDouble(),
            (away?.passesCount ?? 0).toDouble(), primary, textPri, textSec, cardBg, divider),
        _statBar('Fouls', (home?.foulCount ?? 0).toDouble(),
            (away?.foulCount ?? 0).toDouble(), primary, textPri, textSec, cardBg, divider),
        _statBar('Corners', (home?.cornerCount ?? 0).toDouble(),
            (away?.cornerCount ?? 0).toDouble(), primary, textPri, textSec, cardBg, divider),
      ],
    );
  }

  Widget _statBar(String label, double home, double away, Color primary,
      Color textPri, Color textSec, Color cardBg, Color divider) {
    final total = home + away;
    final homePct = total == 0 ? 0.5 : home / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${home.toInt()}',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPri)),
              Text(label,
                  style: GoogleFonts.inter(fontSize: 12, color: textSec)),
              Text('${away.toInt()}',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPri)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: (homePct * 100).round(),
                  child: Container(height: 8, color: primary),
                ),
                Expanded(
                  flex: ((1 - homePct) * 100).round(),
                  child: Container(
                      height: 8, color: AppColors.darkSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardBadge(Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      width: 10,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _playerStatsTab(bool isDark, Color primary, Color cardBg, Color textPri,
      Color textSec, Color divider) {
    final box = Hive.box<PlayerStats>('player_stats');
    final stats =
        box.values.where((s) => s.matchId == widget.match.backendId).toList();

    final homeTeam = widget.match.homeTeam;
    final awayTeam = widget.match.awayTeam;
    final activeTeam = _selectedTeamIndex == 0 ? homeTeam : awayTeam;
    final activePlayers = activeTeam.players;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTeamIndex = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTeamIndex == 0 ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            homeTeam.logo,
                            width: 18,
                            height: 18,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.shield, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              homeTeam.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedTeamIndex == 0 ? Colors.white : textSec,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTeamIndex = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTeamIndex == 1 ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            awayTeam.logo,
                            width: 18,
                            height: 18,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.shield, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              awayTeam.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedTeamIndex == 1 ? Colors.white : textSec,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: activePlayers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: textSec.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('No roster available for ${activeTeam.name}',
                          style: GoogleFonts.inter(fontSize: 14, color: textSec)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: activePlayers.length,
                  itemBuilder: (_, i) {
                    final player = activePlayers[i];
                    final pStatList = stats.where((s) => s.playerId == player.backendId).toList();
                    final s = pStatList.isNotEmpty ? pStatList.first : null;
                    final isMvp = s?.isMvp ?? false;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PlayerDetailsPage(player: player)),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isMvp
                                  ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                                  : divider),
                          boxShadow: isMvp
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                                      blurRadius: 8)
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: isMvp
                                    ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                                    : primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  player.number > 0 ? '#${player.number}' : (player.name.isNotEmpty ? player.name[0].toUpperCase() : '?'),
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isMvp ? const Color(0xFFFFD700) : primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(player.name,
                                            style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: textPri)),
                                      ),
                                      if (isMvp) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.star_rounded,
                                            color: Color(0xFFFFD700), size: 16),
                                        Text('MVP',
                                            style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFFFFD700))),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s != null
                                        ? '${player.position} · ${s.goals ?? 0} G · ${s.assists ?? 0} A · ${s.topSpeed?.toStringAsFixed(1) ?? '0.0'} km/h'
                                        : (player.position.isNotEmpty ? player.position : 'N/A'),
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: textSec),
                                  ),
                                ],
                              ),
                            ),
                            if (s != null && (s.yellowCards! > 0 || s.redCards! > 0))
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (s.yellowCards! > 0)
                                    _cardBadge(const Color(0xFFFFC107)),
                                  if (s.redCards! > 0)
                                    _cardBadge(AppColors.darkError),
                                ],
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
