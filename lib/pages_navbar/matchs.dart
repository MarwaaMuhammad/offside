import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/pages_details/details_match.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  DateTime selectedDate = DateTime.now();
  String searchQuery = "";

  String formatDate(DateTime date) {
    return DateFormat("EEEE, dd MMM yyyy").format(date);
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset('asset/logo2.png', fit: BoxFit.contain), 
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => selectedDate = selectedDate.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.arrow_back_ios, size: 16),
          ),
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
          ),
          IconButton(
            onPressed: () => setState(() => selectedDate = selectedDate.add(const Duration(days: 1))),
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search teams or leagues...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          if (searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                formatDate(selectedDate),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

          Expanded(
            child: ValueListenableBuilder<Box<League>>(
              valueListenable: Hive.box<League>('leagues').listenable(),
              builder: (context, box, _) {
                final allLeagues = box.values.toList();
                if (allLeagues.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_soccer, size: 64, color: colorScheme.outline.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text("No leagues data available"),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: allLeagues.length,
                  itemBuilder: (context, lIdx) {
                    final league = allLeagues[lIdx];

                    List<Match2> displayMatches;
                    if (searchQuery.isNotEmpty) {
                      displayMatches = league.matches.where((m) =>
                        m.homeTeam.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        m.awayTeam.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        league.name.toLowerCase().contains(searchQuery.toLowerCase())
                      ).toList();
                    } else {
                      displayMatches = league.matches.where((m) => isSameDay(m.date, selectedDate)).toList();
                    }

                    if (displayMatches.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Row(
                            children: [
                              Image.asset(league.logo, width: 24, height: 24),
                              const SizedBox(width: 12),
                              Text(
                                league.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...displayMatches.map((match) {
                          final now = DateTime.now();
                          final isUpcoming = now.isBefore(match.date);
                          final isLive = now.isAfter(match.date) &&
                              now.isBefore(match.date.add(const Duration(minutes: 105)));

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => MatchDetailsPage(match: match, league: league)),
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              match.homeTeam.name,
                                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                              textAlign: TextAlign.end,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Image.asset(match.homeTeam.logo, width: 32, height: 32),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        children: [
                                          Text(
                                            isUpcoming 
                                              ? DateFormat('dd MMM').format(match.date) 
                                              : "${match.homeTeamScore} - ${match.awayTeamScore}",
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isLive ? colorScheme.error : colorScheme.onSurface,
                                            ),
                                          ),
                                          if (isUpcoming)
                                            Text(
                                              DateFormat('HH:mm').format(match.date),
                                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                                            ),
                                          if (isLive)
                                            Text(
                                              "LIVE",
                                              style: TextStyle(
                                                color: colorScheme.error,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Image.asset(match.awayTeam.logo, width: 32, height: 32),
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Text(
                                              match.awayTeam.name,
                                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
