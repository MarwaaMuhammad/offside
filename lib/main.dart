import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:offside/models/event_model.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/models/match_stats_model.dart';
import 'package:offside/models/player_stats_model.dart';
import 'package:offside/models/team_stats_model.dart';
import 'package:offside/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Registering Adapters with Unique Type IDs
  Hive.registerAdapter(LeagueAdapter());      // ID: 0
  Hive.registerAdapter(Match2Adapter());      // ID: 1
  Hive.registerAdapter(TeamAdapter());        // ID: 2
  Hive.registerAdapter(PlayerAdapter());      // ID: 3
  Hive.registerAdapter(EventAdapter());       // ID: 4
  // Hive.registerAdapter(MatchStatsAdapter());  // ID: 5
  // Hive.registerAdapter(PlayerStatsAdapter()); // ID: 6
  // Hive.registerAdapter(TeamStatsAdapter());   // ID: 7
  //
  await Hive.openBox<League>('leagues');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offside',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}
