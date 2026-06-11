import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:offside/models/event_model.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/models/match_stats_model.dart';
import 'package:offside/models/player_stats_model.dart';
import 'package:offside/models/team_stats_model.dart';
import 'package:offside/models/invitation_model.dart';
import 'package:offside/splash_screen.dart';
import 'package:offside/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🛠️ Ignore noisy framework-level font assertion errors that crash the app in web/debug
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionStr = details.exception.toString();
    if (exceptionStr.contains('_scheduleSystemFontsUpdate') ||
        exceptionStr.contains('RenderParagraph._scheduleSystemFontsUpdate')) {
      debugPrint('Ignored framework font assertion: $exceptionStr');
      return;
    }
    originalOnError?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final errorStr = error.toString();
    if (errorStr.contains('_scheduleSystemFontsUpdate') ||
        errorStr.contains('RenderParagraph._scheduleSystemFontsUpdate')) {
      debugPrint('Ignored async/platform font assertion: $errorStr');
      return true; // Mark as handled
    }
    return false; // Let other handlers handle it
  };

  // 🚀 Start preloading Google Fonts in the background
  // We don't await this so it doesn't block app startup, but starts the download immediately.
  GoogleFonts.pendingFonts([
    GoogleFonts.inter(),
    GoogleFonts.inter(fontWeight: FontWeight.w500),
    GoogleFonts.inter(fontWeight: FontWeight.w600),
    GoogleFonts.inter(fontWeight: FontWeight.w700),
    GoogleFonts.inter(fontWeight: FontWeight.w800),
    GoogleFonts.inter(fontWeight: FontWeight.w900),
  ]);

  // 🚀 Initialize Supabase
  await Supabase.initialize(
    url: 'https://gsvowvzdxphlguclawur.supabase.co',
    anonKey: 'sb_publishable_vuHhBKjf4kJJgPnkFlNm9A_ErI2gVd_', 
  );

  await Hive.initFlutter();

  // Registering Adapters
  Hive.registerAdapter(LeagueAdapter());      
  Hive.registerAdapter(Match2Adapter());      
  Hive.registerAdapter(TeamAdapter());        
  Hive.registerAdapter(PlayerAdapter());      
  Hive.registerAdapter(EventAdapter());       
  
  try {
    Hive.registerAdapter(MatchStatsAdapter());  
    Hive.registerAdapter(PlayerStatsAdapter()); 
    Hive.registerAdapter(TeamStatsAdapter());   
    Hive.registerAdapter(InvitationAdapter()); 
  } catch (_) {}
  
  await Hive.openBox<League>('leagues');
  await Hive.openBox<Invitation>('invitations'); 
  await Hive.openBox<Player>('players'); 
  await Hive.openBox<MatchStats>('match_stats');
  await Hive.openBox<PlayerStats>('player_stats');
  await Hive.openBox<TeamStats>('team_stats');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Offside',
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
