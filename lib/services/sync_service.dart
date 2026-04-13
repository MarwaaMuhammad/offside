import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/models/player_model.dart';
import 'api_service.dart';

class SyncService {
  static Future<void> syncLeagueToBackend(League league) async {
    try {
      final tournament = await ApiService.createTournament(
        name: league.name,
        startDate: league.startDate,
        endDate: league.endDate,
      );
      league.backendId = tournament['id']?.toString() ?? tournament['tournament_id']?.toString();

      for (final team in league.teams) {
        final remoteTeam = await ApiService.createTeam(
          name: team.name,
          primaryColor: team.primaryColor,
          secondaryColor: team.secondaryColor,
          playerNames: team.players.map((p) => p.name).toList(),
        );
        team.backendId = remoteTeam['id']?.toString() ?? remoteTeam['team_id']?.toString();

        for (final player in team.players) {
          final remotePlayer = await ApiService.createPlayer(
            teamId: team.backendId!,
            fullName: player.name,
            jerseyNumber: player.number,
            nationality: player.nationality,
            height: player.height ?? 0.0,
            weight: player.weight ?? 0.0,
            position: player.position,
          );
          player.backendId = remotePlayer['id']?.toString() ?? remotePlayer['player_id']?.toString();
        }
      }

      for (final match in league.matches) {
        if (league.backendId == null) continue;
        final remoteMatch = await ApiService.createMatch(
          tournamentId: league.backendId!,
          matchDate: match.date,
          videoUrl: match.videoUrl,
        );
        match.backendId = remoteMatch['id']?.toString() ?? remoteMatch['match_id']?.toString();
      }
      await league.save();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> syncMatchResult(Match2 match, League league, {bool isFinished = false}) async {
    if (match.backendId == null) return;

    try {
      await ApiService.updateMatch(
        match.backendId!,
        scoreTeamA: match.homeTeamScore ?? 0,
        scoreTeamB: match.awayTeamScore ?? 0,
        status: isFinished ? 'finished' : 'live',
        endTime: isFinished ? DateTime.now() : null,
      );

      // Sync stats
      if (isFinished) {
        await ApiService.submitMatchStats(
          matchId: match.backendId!,
          teamId: match.homeTeam.backendId ?? "",
          goalCount: match.homeTeamScore ?? 0,
        );
        await ApiService.submitMatchStats(
          matchId: match.backendId!,
          teamId: match.awayTeam.backendId ?? "",
          goalCount: match.awayTeamScore ?? 0,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
