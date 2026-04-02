import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/team_model.dart';
import 'api_service.dart';

/// SyncService is the bridge between your local Hive data and the backend.
/// Call these methods after the user performs an action locally.
class SyncService {
  // ─────────────────────────────────────────────────────────────
  //  STEP 1: When user saves a League → push it to the backend
  // ─────────────────────────────────────────────────────────────

  /// Call this right after `leagueBox.add(league)` in add_matches.dart.
  /// It creates the tournament + all teams on the backend, then stores
  /// the returned backend IDs back onto the local objects.
  static Future<void> syncLeagueToBackend(League league) async {
    try {
      // 1. Create tournament on backend
      final tournament = await ApiService.createTournament(name: league.name);
      final tournamentId = tournament['id'] as String;
      league.backendId = tournamentId;

      // 2. Create every team on the backend
      for (final team in league.teams) {
        final remoteTeam = await ApiService.createTeam(name: team.name);
        team.backendId = remoteTeam['id'] as String;
      }

      // 3. Create every match (fixture) on the backend
      for (final match in league.matches) {
        final homeBackendId = match.homeTeam.backendId;
        final awayBackendId = match.awayTeam.backendId;

        if (homeBackendId == null || awayBackendId == null) {
          print('⚠️  Skipping match — team backendId is null');
          continue;
        }

        final remoteMatch = await ApiService.createMatch(
          tournamentId: tournamentId,
          teamAId: homeBackendId,
          teamBId: awayBackendId,
          startTime: match.date,
          status: 'scheduled',
        );
        match.backendId = remoteMatch['id'] as String;
      }

      // 4. Persist the backend IDs locally
      await league.save();

      print('✅ League "${league.name}" synced to backend!');
    } on ApiException catch (e) {
      print('❌ API error during league sync: $e');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error during league sync: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 2: When a match is scored → push result + stats
  // ─────────────────────────────────────────────────────────────

  /// Call this after the user finishes entering events in add_Score_match.dart.
  /// Pass [isFinished] = true to mark the match as "finished" on the backend.
  static Future<void> syncMatchResult(
    Match2 match,
    League league, {
    bool isFinished = false,
  }) async {
    final matchBackendId = match.backendId;
    if (matchBackendId == null) {
      print('⚠️  Match has no backendId — was syncLeagueToBackend called?');
      return;
    }

    try {
      // 1. Determine winner
      String? winnerId;
      if (isFinished &&
          match.homeTeamScore != null &&
          match.awayTeamScore != null) {
        if (match.homeTeamScore! > match.awayTeamScore!) {
          winnerId = match.homeTeam.backendId;
        } else if (match.awayTeamScore! > match.homeTeamScore!) {
          winnerId = match.awayTeam.backendId;
        }
        // draw → winnerId stays null
      }

      // 2. Update score + status on the backend
      await ApiService.updateMatch(
        matchBackendId,
        scoreTeamA: match.homeTeamScore ?? 0,
        scoreTeamB: match.awayTeamScore ?? 0,
        status: isFinished ? 'finished' : 'live',
        winnerId: winnerId,
        endTime: isFinished ? DateTime.now() : null,
      );

      // 3. Compute stats from local events for home team
      final homeStats = _computeStats(match, isHome: true);
      final awayStats = _computeStats(match, isHome: false);

      final homeBackendId = match.homeTeam.backendId;
      final awayBackendId = match.awayTeam.backendId;

      if (homeBackendId != null) {
        await ApiService.submitTeamMatchStats(
          matchId: matchBackendId,
          teamId: homeBackendId,
          goals: homeStats['goals']!,
          shots: homeStats['shots']!,
          fouls: homeStats['fouls']!,
          yellowCards: homeStats['yellowCards']!,
          redCards: homeStats['redCards']!,
          offsides: homeStats['offsides']!,
          corners: homeStats['corners']!,
          passes: homeStats['passes']!,
        );
      }

      if (awayBackendId != null) {
        await ApiService.submitTeamMatchStats(
          matchId: matchBackendId,
          teamId: awayBackendId,
          goals: awayStats['goals']!,
          shots: awayStats['shots']!,
          fouls: awayStats['fouls']!,
          yellowCards: awayStats['yellowCards']!,
          redCards: awayStats['redCards']!,
          offsides: awayStats['offsides']!,
          corners: awayStats['corners']!,
          passes: awayStats['passes']!,
        );
      }

      print('✅ Match result synced to backend!');
    } on ApiException catch (e) {
      print('❌ API error syncing match result: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Helper: count events per type from local event list
  // ─────────────────────────────────────────────────────────────
  static Map<String, int> _computeStats(Match2 match, {required bool isHome}) {
    final events = isHome ? match.eventsHome : match.eventsAway;

    int goals = 0, shots = 0, yellowCards = 0, redCards = 0;
    int offsides = 0, corners = 0, passes = 0, fouls = 0;

    for (final e in events) {
      switch (e.type) {
        case 'Goal':
          goals++;
          shots++;
          break;
        case 'Shot':
          shots++;
          break;
        case 'Yellow Card':
          yellowCards++;
          fouls++;
          break;
        case 'Red Card':
          redCards++;
          break;
        case 'Offside':
          offsides++;
          break;
        case 'Corner Kick':
          corners++;
          break;
        case 'Free Kick':
          fouls++;
          break;
      }
    }

    // Also use cumulative player stats for passes
    final team = isHome ? match.homeTeam : match.awayTeam;
    passes = team.players.fold(0, (sum, p) => sum + p.passes);

    return {
      'goals': goals,
      'shots': shots,
      'yellowCards': yellowCards,
      'redCards': redCards,
      'offsides': offsides,
      'corners': corners,
      'passes': passes,
      'fouls': fouls,
    };
  }
}
