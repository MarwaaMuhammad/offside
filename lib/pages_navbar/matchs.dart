import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/pages_details/details_match.dart';
import 'package:offside/theme_provider.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage>
    with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  String searchQuery = '';
  late TabController _tabController;

  // Date strip: 7 days centred on today
  late List<DateTime> _dateStrip;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _buildDateStrip();
  }

  void _buildDateStrip() {
    final now = DateTime.now();
    _dateStrip = List.generate(
        14, (i) => DateTime(now.year, now.month, now.day - 3 + i));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  String _matchStatus(Match2 m) {
    final now = DateTime.now();
    if (now.isBefore(m.date)) return 'upcoming';
    if (now.isBefore(m.date.add(const Duration(minutes: 105)))) return 'live';
    return 'finished';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPri = isDark ? AppColors.darkTextPri : AppColors.lightTextPri;
    final textSec = isDark ? AppColors.darkTextSec : AppColors.lightTextSec;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Image.asset('asset/logo2.png',
                      height: 36, fit: BoxFit.contain),
                  const Spacer(),
                  Text(
                    'Matches',
                    style: GoogleFonts.inter(
                      color: textPri,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context)
                                .colorScheme
                                .copyWith(primary: primary),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                        ),
                      ),
                      child: Icon(Icons.calendar_today_outlined,
                          color: primary, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search Bar ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.lightDivider,
                  ),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => searchQuery = v),
                  style: GoogleFonts.inter(
                      color: textPri, fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search teams or leagues…',
                    hintStyle:
                        GoogleFonts.inter(color: textSec, fontSize: 13),
                    prefixIcon:
                        Icon(Icons.search, color: textSec, size: 20),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Date Strip ───────────────────────────
            if (searchQuery.isEmpty)
              SizedBox(
                height: 68,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _dateStrip.length,
                  itemBuilder: (ctx, i) {
                    final d = _dateStrip[i];
                    final isSelected = isSameDay(d, selectedDate);
                    final isToday = isSameDay(d, DateTime.now());
                    return GestureDetector(
                      onTap: () => setState(() => selectedDate = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primary
                              : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? primary
                                : (isDark
                                    ? AppColors.darkDivider
                                    : AppColors.lightDivider),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primary.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEE').format(d).toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.black
                                    : textSec,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${d.day}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.black
                                    : textPri,
                              ),
                            ),
                            if (isToday && !isSelected)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),

            // ── Match List ───────────────────────────
            Expanded(
              child: ValueListenableBuilder<Box<League>>(
                valueListenable:
                    Hive.box<League>('leagues').listenable(),
                builder: (context, box, _) {
                  final allLeagues = box.values.toList();
                  if (allLeagues.isEmpty) {
                    return _emptyState(
                        'No matches yet', Icons.sports_soccer, textSec);
                  }

                  final leaguesWithMatches = <League, List<Match2>>{};
                  for (final l in allLeagues) {
                    final matches = searchQuery.isNotEmpty
                        ? l.matches
                            .where((m) =>
                                m.homeTeam.name
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase()) ||
                                m.awayTeam.name
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase()) ||
                                l.name
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase()))
                            .toList()
                        : l.matches
                            .where((m) => isSameDay(m.date, selectedDate))
                            .toList();
                    if (matches.isNotEmpty) leaguesWithMatches[l] = matches;
                  }

                  if (leaguesWithMatches.isEmpty) {
                    return _emptyState(
                        'No matches on this day',
                        Icons.event_busy_outlined,
                        textSec);
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    children: leaguesWithMatches.entries.map((e) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _leagueHeader(e.key, primary, textSec),
                          const SizedBox(height: 6),
                          ...e.value.map((m) =>
                              _matchCard(m, isDark, primary, textPri,
                                  textSec, cardBg, e.key)),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leagueHeader(League l, Color primary, Color textSec) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Image.asset(l.logo, width: 20, height: 20),
          const SizedBox(width: 8),
          Text(
            l.name.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: primary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
                color: primary.withOpacity(0.3), thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _matchCard(
    Match2 m,
    bool isDark,
    Color primary,
    Color textPri,
    Color textSec,
    Color cardBg,
    League league,
  ) {
    final status = _matchStatus(m);
    final isLive = status == 'live';
    final isUpcoming = status == 'upcoming';

    final statusColor = isLive
        ? AppColors.darkPrimary
        : isUpcoming
            ? AppColors.darkSecondary
            : (isDark ? AppColors.darkTextSec : AppColors.lightTextSec);

    final statusLabel =
        isLive ? 'LIVE' : isUpcoming ? 'UPCOMING' : 'FT';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                MatchDetailsPage(match: m, league: league)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive
                ? primary.withOpacity(0.4)
                : (isDark
                    ? AppColors.darkDivider
                    : AppColors.lightDivider),
          ),
          boxShadow: isLive
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Status badge row
              Row(
                children: [
                  if (isLive) ...[
                    _livePulseDot(),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (!isLive) ...[
                    const SizedBox(width: 4),
                    Text(
                      '• ${DateFormat('HH:mm').format(m.date)}',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: textSec),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Teams row
              Row(
                children: [
                  // Home team
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            m.homeTeam.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPri,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Image.asset(m.homeTeam.logo,
                            width: 36, height: 36),
                      ],
                    ),
                  ),
                  // Score / Time
                  Container(
                    width: 80,
                    alignment: Alignment.center,
                    child: isUpcoming
                        ? Column(
                            children: [
                              Text(
                                DateFormat('dd MMM').format(m.date),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: textSec,
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm').format(m.date),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textPri,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            '${m.homeTeamScore}  –  ${m.awayTeamScore}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isLive ? primary : textPri,
                            ),
                          ),
                  ),
                  // Away team
                  Expanded(
                    child: Row(
                      children: [
                        Image.asset(m.awayTeam.logo,
                            width: 36, height: 36),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            m.awayTeam.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPri,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _livePulseDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkPrimary,
          boxShadow: [
            BoxShadow(
                color: AppColors.darkPrimary.withOpacity(0.7),
                blurRadius: 6,
                spreadRadius: 1)
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg, IconData icon, Color textSec) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: textSec.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(msg,
              style: GoogleFonts.inter(
                  fontSize: 15, color: textSec)),
        ],
      ),
    );
  }
}
