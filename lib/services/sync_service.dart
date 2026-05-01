import 'package:hive/hive.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/models/player_model.dart';
import 'api_service.dart';

class SyncService {
  /// Fetches everything from Supabase and populates Hive
  static Future<void> fetchAllLeaguesFromBackend() async {
    try {
      print("📡 [Sync] Fetching all data from backend...");
      
      final tournamentsJson = await ApiService.fetchTournaments() as List<dynamic>;
      final teamsJson = await ApiService.fetchTeams() as List<dynamic>;
      final matchesJson = await ApiService.fetchMatches() as List<dynamic>;
      final playersJson = await ApiService.getAllPlayers() as List<dynamic>;

      print("📊 [Sync] Data received: ${tournamentsJson.length} Tournaments, ${teamsJson.length} Teams, ${playersJson.length} Players");

      final leagueBox = Hive.box<League>('leagues');
      final playerBox = Hive.box<Player>('players');
      
      await leagueBox.clear();
      await playerBox.clear();

      // 1. Process all players and map them to teams efficiently
      Map<String, List<Player>> teamPlayersMap = {};
      for (var pJson in playersJson) {
        final pId = (pJson['player_id'] ?? pJson['id']).toString();
        
        // Use exactly 'jersey_number' as seen in user's Supabase screenshot
        int jNumber = 0;
        final rawNumber = pJson['jersey_number'] ?? pJson['number'];
        if (rawNumber != null) {
          if (rawNumber is int) {
            jNumber = rawNumber;
          } else if (rawNumber is String) {
            jNumber = int.tryParse(rawNumber) ?? 0;
          } else if (rawNumber is num) {
            jNumber = rawNumber.toInt();
          }
        }

        final player = Player(
          name: pJson['full_name'] ?? "Unknown",
          position: pJson['position'] ?? "N/A",
          age: pJson['age'] ?? 20,
          nationality: pJson['nationality'] ?? "",
          number: jNumber,
          height: (pJson['height'] as num?)?.toDouble(),
          weight: (pJson['weight'] as num?)?.toDouble(),
          backendId: pId,
          image: pJson['image_url'], 
        );
        
        await playerBox.add(player);
        
        final tId = pJson['team_id']?.toString();
        if (tId != null) {
          teamPlayersMap.putIfAbsent(tId, () => []).add(player);
        }
      }

      // 2. Map Teams using the teamPlayersMap
      Map<String, Team> teamMap = {};
      for (var tJson in teamsJson) {
        String tId = (tJson['team_id'] ?? tJson['id']).toString();
        List<Player> teamPlayers = teamPlayersMap[tId] ?? [];

        final team = Team(
          name: tJson['team_name'] ?? "Unknown Team",
          logo: "asset/Teams_Logo/1.png",
          players: teamPlayers,
          primaryColor: tJson['primary_tshirt_colors'],
          secondaryColor: tJson['secondary _tshirt_colors'],
          goalkeeperColor: tJson['goalkeeper_tshirt_colors'],
          backendId: tId,
        );
        teamMap[tId] = team;
      }

      // 3. Map Matches to Tournaments
      for (var tourJson in tournamentsJson) {
        String tourId = (tourJson['tournament_id'] ?? tourJson['id']).toString();
        
        List<Match2> leagueMatches = [];
        List<Team> leagueTeams = [];
        Set<String> addedTeamIds = {};

        final relatedMatches = matchesJson.where((m) => m['tournament_id']?.toString() == tourId);
        
        for (var mJson in relatedMatches) {
          String? hId = mJson['home_team_id']?.toString();
          String? aId = mJson['away_team_id']?.toString();
          
          if (hId != null && aId != null && teamMap.containsKey(hId) && teamMap.containsKey(aId)) {
            final match = Match2(
              homeTeam: teamMap[hId]!,
              awayTeam: teamMap[aId]!,
              date: DateTime.parse(mJson['match_date']),
              backendId: (mJson['match_id'] ?? mJson['id']).toString(),
              videoUrl: mJson['video_url'],
              homeTeamScore: mJson['home_score'] ?? 0,
              awayTeamScore: mJson['away_score'] ?? 0,
            );
            leagueMatches.add(match);
            
            if (addedTeamIds.add(hId)) leagueTeams.add(teamMap[hId]!);
            if (addedTeamIds.add(aId)) leagueTeams.add(teamMap[aId]!);
          }
        }

        final league = League(
          logo: "asset/leagues_logo/1.png",
          name: tourJson['tournament_name'] ?? "Unknown League",
          teams: leagueTeams,
          matches: leagueMatches,
          backendId: tourId,
          startDate: tourJson['start_date'] != null ? DateTime.parse(tourJson['start_date']) : null,
          endDate: tourJson['end_date'] != null ? DateTime.parse(tourJson['end_date']) : null,
        );
        
        await leagueBox.add(league);
      }
      print("🏁 [Sync] Success! Check your app now.");
    } catch (e) {
      print("❌ [Sync] Critical Error: $e");
    }
  }

  static Future<void> syncLeagueToBackend(League league) async {
    try {
      print("📡 [Sync] Starting Full League Sync: ${league.name}");

      final tournament = await ApiService.createTournament(
        name: league.name,
        startDate: league.startDate ?? DateTime.now(),
        endDate: league.endDate ?? DateTime.now().add(const Duration(days: 30)),
      );
      
      final tId = tournament['id'] ?? tournament['tournament_id'];
      if (tId == null) throw Exception("Failed to get Tournament ID from backend");
      league.backendId = tId.toString();

      for (final team in league.teams) {
        final remoteTeam = await ApiService.createTeam(
          name: team.name,
          primaryColor: team.primaryColor ?? "#0000FF",
          secondaryColor: team.secondaryColor ?? "#FFFFFF",
          goalkeeperColor: team.goalkeeperColor ?? "#FFFF00",
        );
        
        final tmId = remoteTeam['id'] ?? remoteTeam['team_id'];
        if (tmId == null) continue;
        team.backendId = tmId.toString();

        for (final player in team.players) {
          try {
            if (player.backendId != null) {
              // PLAYER EXISTS -> UPDATE JERSEY AND TEAM
              print("🔄 [Sync] Updating existing player: ${player.name} (Jersey: #${player.number})");
              await ApiService.updatePlayer(
                playerId: player.backendId!,
                jerseyNumber: player.number,
                teamId: team.backendId,
              );
            } else {
              // NEW PLAYER -> CREATE
              print("🆕 [Sync] Creating new player: ${player.name}");
              final remotePlayer = await ApiService.createPlayer(
                fullName: player.name,
                jerseyNumber: player.number,
                nationality: player.nationality,
                height: player.height ?? 175.0,
                weight: player.weight ?? 70.0,
                position: player.position,
                email: "player_${DateTime.now().millisecondsSinceEpoch}_${player.number}@offside.com", 
                phoneNumber: "01000000000",
                teamId: team.backendId, 
              );
              player.backendId = (remotePlayer['player_id'] ?? remotePlayer['id']).toString();
            }
          } catch (e) {
            print("❌ [Sync] Error syncing player ${player.name}: $e");
          }
        }
      }

      for (final match in league.matches) {
        if (league.backendId != null && match.homeTeam.backendId != null && match.awayTeam.backendId != null) {
          final remoteMatch = await ApiService.createMatch(
            tournamentId: league.backendId!,
            homeTeamId: match.homeTeam.backendId!,
            awayTeamId: match.awayTeam.backendId!,
            matchDate: match.date,
            videoUrl: match.videoUrl,
          );
          match.backendId = (remoteMatch['match_id'] ?? remoteMatch['id']).toString();
        }
      }

      await league.save();
      print("🏁 [Sync] Full League Sync Completed!");
    } catch (e) {
      print("❌ [Sync] Critical Sync Error: $e");
      rethrow;
    }
  }

  static Future<void> syncMatchResult(Match2 match, League league, {bool isFinished = false}) async {
    if (match.backendId == null) return;
    try {
      if (match.homeTeam.backendId != null) {
        await ApiService.submitTeamStats(
          matchId: match.backendId!,
          teamId: match.homeTeam.backendId!,
          goals: match.homeTeamScore ?? 0,
          passes: 0, fouls: 0, corners: 0,
        );
      }
      if (match.awayTeam.backendId != null) {
        await ApiService.submitTeamStats(
          matchId: match.backendId!,
          teamId: match.awayTeam.backendId!,
          goals: match.awayTeamScore ?? 0,
          passes: 0, fouls: 0, corners: 0,
        );
      }
    } catch (e) {
      print("❌ [Sync Stats] Error: $e");
    }
  }
}
