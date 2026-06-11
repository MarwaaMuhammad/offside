import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:offside/models/leage_model.dart';
import 'package:offside/models/match_model.dart';
import 'package:offside/models/team_model.dart';
import 'package:offside/models/player_model.dart';
import 'package:offside/models/match_stats_model.dart';
import 'package:offside/models/player_stats_model.dart';
import 'api_service.dart';

class SyncService {
  // ─────────────────────────────────────────────────────────────────
  //  SAFE FETCH HELPER
  //  Wraps a single API call; returns [] on any error and logs fully.
  // ─────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> _safeFetch(
    String tableName,
    Future<List<dynamic>> Function() fetcher,
  ) async {
    try {
      final result = await fetcher();
      debugPrint('✅ [Sync] $tableName → ${result.length} rows');
      return result;
    } on ApiException catch (e, stack) {
      debugPrint('❌ [Sync] $tableName fetch failed');
      debugPrint('   Status : ${e.statusCode}');
      debugPrint('   URL    : ${e.url ?? "unknown"}');
      debugPrint('   Body   : ${e.message.length > 500 ? '${e.message.substring(0, 500)}…' : e.message}');
      debugPrint('   Stack  : $stack');
      return [];
    } catch (e, stack) {
      debugPrint('❌ [Sync] $tableName unexpected error: $e');
      debugPrint('   Stack  : $stack');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  FETCH ALL FROM BACKEND → POPULATE HIVE
  // ─────────────────────────────────────────────────────────────────
  static Future<void> fetchAllLeaguesFromBackend() async {
    debugPrint('📡 [Sync] Starting full data fetch from backend…');

    // Each table is fetched independently — one failure does NOT stop others.
    final tournamentsJson = await _safeFetch('TOURNAMENTS', ApiService.fetchTournaments);
    final teamsJson       = await _safeFetch('TEAMS',       ApiService.fetchTeams);
    final matchesJson     = await _safeFetch('MATCHES',     ApiService.fetchMatches);
    final playersJson     = await _safeFetch('PLAYERS',     ApiService.getAllPlayers);
    final playerStatsJson = await _safeFetch('PLAYER_MATCH_STATS', ApiService.fetchPlayerMatchStats);
    final teamStatsJson   = await _safeFetch('TEAM_MATCH_STATS',   ApiService.fetchTeamMatchStats);

    debugPrint('📊 [Sync] Received: ${tournamentsJson.length} tournaments, '
        '${teamsJson.length} teams, ${matchesJson.length} matches, '
        '${playersJson.length} players, ${playerStatsJson.length} player-stats, '
        '${teamStatsJson.length} team-stats');

    // Open Hive boxes
    final leagueBox     = Hive.box<League>('leagues');
    final playerBox     = Hive.box<Player>('players');
    final matchStatsBox = Hive.box<MatchStats>('match_stats');
    final playerStatsBox = Hive.box<PlayerStats>('player_stats');

    await leagueBox.clear();
    await playerBox.clear();
    await matchStatsBox.clear();
    await playerStatsBox.clear();

    // ── 1. Players ────────────────────────────────────────────────
    Map<String, List<Player>> teamPlayersMap = {};
    Map<String, Player> playerMap = {};

    for (var pJson in playersJson) {
      try {
        final pId = (pJson['player_id'] ?? pJson['id']).toString();

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

        // Aggregate per-match stats for this player
        int goals = 0, assists = 0, appearances = 0, yellowCards = 0, redCards = 0;
        double maxSpeed = 0.0, totalDist = 0.0;

        final pStats = playerStatsJson.where((s) => s['player_id']?.toString() == pId);
        for (var s in pStats) {
          appearances++;
          goals       += (s['goals']       as num?)?.toInt()    ?? 0;
          assists     += (s['assists']      as num?)?.toInt()    ?? 0;
          yellowCards += (s['yellow_card']  as num?)?.toInt()    ?? 0;
          redCards    += (s['red_card']     as num?)?.toInt()    ?? 0;
          final speed  = (s['top_speed']    as num?)?.toDouble() ?? 0.0;
          if (speed > maxSpeed) maxSpeed = speed;
          totalDist   += (s['total_distance'] as num?)?.toDouble() ?? 0.0;

          try {
            await playerStatsBox.add(PlayerStats(
              backendId:       (s['player_stat_id'] ?? s['id']).toString(),
              playerId:        pId,
              matchId:         s['match_id']?.toString(),
              topSpeed:        (s['top_speed']        as num?)?.toDouble() ?? 0.0,
              totalDistance:   (s['total_distance']   as num?)?.toDouble() ?? 0.0,
              goals:           (s['goals']            as num?)?.toInt()    ?? 0,
              assists:         (s['assists']          as num?)?.toInt()    ?? 0,
              yellowCards:     (s['yellow_card']      as num?)?.toInt()    ?? 0,
              redCards:        (s['red_card']         as num?)?.toInt()    ?? 0,
              isMvp:           s['is_mvp'] ?? false,
              acquisition:     (s['acquisition']      as num?)?.toDouble() ?? 0.0,
              actionsDetected: s['actions_detected'] is Map ? s['actions_detected'] : null,
              heatmapImageUrl: s['heatmap_image_url'],
            ));
          } catch (e) {
            debugPrint('⚠️  [Sync] Could not store PlayerStats for player $pId: $e');
          }
        }

        final player = Player(
          name:          pJson['full_name']   ?? 'Unknown',
          position:      pJson['position']    ?? 'N/A',
          age:           pJson['age']         ?? 20,
          nationality:   pJson['nationality'] ?? '',
          number:        jNumber,
          height:        (pJson['height']     as num?)?.toDouble(),
          weight:        (pJson['weight']     as num?)?.toDouble(),
          backendId:     pId,
          image:         pJson['image_url'],
          goals:         goals,
          assists:       assists,
          appearances:   appearances,
          yellowCards:   yellowCards,
          redCards:      redCards,
          highestSpeed:  maxSpeed,
          totalDistance: totalDist,
        );

        await playerBox.add(player);
        playerMap[pId] = player;

        final tId = pJson['team_id']?.toString();
        if (tId != null) {
          teamPlayersMap.putIfAbsent(tId, () => []).add(player);
        }
      } catch (e, stack) {
        debugPrint('⚠️  [Sync] Error mapping player ${pJson['player_id']}: $e\n$stack');
      }
    }

    // ── 2. Teams ──────────────────────────────────────────────────
    Map<String, Team> teamMap = {};
    for (var tJson in teamsJson) {
      try {
        final tId = (tJson['team_id'] ?? tJson['id']).toString();
        final team = Team(
          name:            tJson['team_name']               ?? 'Unknown Team',
          logo:            tJson['logo_url']                ?? 'asset/Teams_Logo/1.png',
          players:         teamPlayersMap[tId]              ?? [],
          primaryColor:    tJson['primary_tshirt_colors'],
          secondaryColor:  tJson['secondary_tshirt_colors'],
          goalkeeperColor: tJson['goalkeeper_tshirt_colors'],
          backendId:       tId,
        );
        teamMap[tId] = team;
      } catch (e, stack) {
        debugPrint('⚠️  [Sync] Error mapping team ${tJson['team_id']}: $e\n$stack');
      }
    }

    // ── 3. Leagues / Tournaments ──────────────────────────────────
    for (var tourJson in tournamentsJson) {
      try {
        final tourId = (tourJson['tournament_id'] ?? tourJson['id']).toString();

        List<Match2> leagueMatches = [];
        List<Team>   leagueTeams  = [];
        Set<String>  addedTeamIds = {};

        final relatedMatches = matchesJson.where(
          (m) => m['tournament_id']?.toString() == tourId,
        );

        for (var mJson in relatedMatches) {
          try {
            final hId = mJson['home_team_id']?.toString();
            final aId = mJson['away_team_id']?.toString();
            final mId = (mJson['match_id'] ?? mJson['id']).toString();

            if (hId == null || aId == null) continue;
            if (!teamMap.containsKey(hId) || !teamMap.containsKey(aId)) {
              debugPrint('⚠️  [Sync] Match $mId references unknown team(s): home=$hId away=$aId');
              continue;
            }

            final hStats = teamStatsJson.firstWhere(
              (s) => s['match_id']?.toString() == mId && s['team_id']?.toString() == hId,
              orElse: () => null,
            );
            final aStats = teamStatsJson.firstWhere(
              (s) => s['match_id']?.toString() == mId && s['team_id']?.toString() == aId,
              orElse: () => null,
            );

            final homeScore = hStats != null
                ? (hStats['goals'] as num?)?.toInt()
                : (mJson['home_score'] as num?)?.toInt();
            final awayScore = aStats != null
                ? (aStats['goals'] as num?)?.toInt()
                : (mJson['away_score'] as num?)?.toInt();

            leagueMatches.add(Match2(
              homeTeam:      teamMap[hId]!,
              awayTeam:      teamMap[aId]!,
              date:          DateTime.parse(mJson['match_date']),
              backendId:     mId,
              videoUrl:      mJson['video_url'],
              homeTeamScore: homeScore,
              awayTeamScore: awayScore,
            ));

            // Store team match stats
            for (final entry in [(hStats, hId), (aStats, aId)]) {
              final stats = entry.$1;
              final tid   = entry.$2;
              if (stats != null) {
                try {
                  await matchStatsBox.add(MatchStats(
                    matchId:        mId,
                    teamId:         tid,
                    goalCount:      (stats['goals']          as num?)?.toInt()    ?? 0,
                    passesCount:    (stats['passes']         as num?)?.toInt()    ?? 0,
                    foulCount:      (stats['foul']           as num?)?.toInt()    ?? 0,
                    cornerCount:    (stats['corner']         as num?)?.toInt()    ?? 0,
                    acquisitionAvg: (stats['acquisition_avg'] as num?)?.toDouble() ?? 0.0,
                  ));
                } catch (e) {
                  debugPrint('⚠️  [Sync] Could not store MatchStats for match $mId team $tid: $e');
                }
              }
            }

            if (addedTeamIds.add(hId)) leagueTeams.add(teamMap[hId]!);
            if (addedTeamIds.add(aId)) leagueTeams.add(teamMap[aId]!);
          } catch (e, stack) {
            debugPrint('⚠️  [Sync] Error mapping match ${mJson['match_id']}: $e\n$stack');
          }
        }

        await leagueBox.add(League(
          logo:      tourJson['logo_url']        ?? 'asset/leagues_logo/1.png',
          name:      tourJson['tournament_name'] ?? 'Unknown League',
          teams:     leagueTeams,
          matches:   leagueMatches,
          backendId: tourId,
          startDate: tourJson['start_date'] != null ? DateTime.tryParse(tourJson['start_date']) : null,
          endDate:   tourJson['end_date']   != null ? DateTime.tryParse(tourJson['end_date'])   : null,
        ));
      } catch (e, stack) {
        debugPrint('⚠️  [Sync] Error mapping tournament ${tourJson['tournament_id']}: $e\n$stack');
      }
    }

    debugPrint('🏁 [Sync] Complete — ${leagueBox.length} leagues, ${playerBox.length} players in cache.');
  }

  // ─────────────────────────────────────────────────────────────────
  //  SYNC LEAGUE TO BACKEND
  // ─────────────────────────────────────────────────────────────────
  static Future<void> syncLeagueToBackend(League league) async {
    try {
      debugPrint('📡 [Sync] Starting Full League Sync: ${league.name}');

      final tournament = await ApiService.createTournament(
        name:      league.name,
        startDate: league.startDate ?? DateTime.now(),
        endDate:   league.endDate   ?? DateTime.now().add(const Duration(days: 30)),
      );

      final tId = tournament['id'] ?? tournament['tournament_id'];
      if (tId == null) throw Exception('Failed to get Tournament ID from backend');
      league.backendId = tId.toString();

      for (final team in league.teams) {
        try {
          final remoteTeam = await ApiService.createTeam(
            name:            team.name,
            logo:            team.logo,
            primaryColor:    team.primaryColor    ?? '#0000FF',
            secondaryColor:  team.secondaryColor  ?? '#FFFFFF',
            goalkeeperColor: team.goalkeeperColor ?? '#FFFF00',
          );

          final tmId = remoteTeam['id'] ?? remoteTeam['team_id'];
          if (tmId == null) continue;
          team.backendId = tmId.toString();

          for (final player in team.players) {
            try {
              if (player.backendId != null) {
                await ApiService.updatePlayer(
                  playerId:     player.backendId!,
                  jerseyNumber: player.number,
                  teamId:       team.backendId,
                );
              } else {
                final remotePlayer = await ApiService.createPlayer(
                  fullName:    player.name,
                  jerseyNumber: player.number,
                  nationality: player.nationality,
                  height:      player.height      ?? 175.0,
                  weight:      player.weight      ?? 70.0,
                  position:    player.position,
                  email:       'player_${DateTime.now().millisecondsSinceEpoch}_${player.number}@offside.com',
                  phoneNumber: '01000000000',
                  teamId:      team.backendId,
                );
                player.backendId = (remotePlayer['player_id'] ?? remotePlayer['id']).toString();
              }
            } catch (e) {
              debugPrint('❌ [Sync] Error syncing player ${player.name}: $e');
            }
          }
        } catch (e) {
          debugPrint('❌ [Sync] Error syncing team ${team.name}: $e');
        }
      }

      for (final match in league.matches) {
        if (league.backendId != null &&
            match.homeTeam.backendId != null &&
            match.awayTeam.backendId != null) {
          try {
            final remoteMatch = await ApiService.createMatch(
              tournamentId: league.backendId!,
              homeTeamId:   match.homeTeam.backendId!,
              awayTeamId:   match.awayTeam.backendId!,
              matchDate:    match.date,
              videoUrl:     match.videoUrl,
            );
            match.backendId = (remoteMatch['match_id'] ?? remoteMatch['id']).toString();
          } catch (e) {
            debugPrint('❌ [Sync] Error syncing match: $e');
          }
        }
      }

      await league.save();
      debugPrint('🏁 [Sync] Full League Sync Completed!');
    } catch (e, stack) {
      debugPrint('❌ [Sync] Critical Sync Error: $e\n$stack');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  SYNC MATCH RESULT
  // ─────────────────────────────────────────────────────────────────
  static Future<void> syncMatchResult(
    Match2 match,
    League league, {
    bool isFinished = false,
  }) async {
    if (match.backendId == null) return;
    try {
      if (match.homeTeam.backendId != null) {
        await ApiService.submitTeamMatchStats(
          matchId: match.backendId!,
          teamId:  match.homeTeam.backendId!,
          goals:   match.homeTeamScore ?? 0,
          passes:  0, fouls: 0, corners: 0,
        );
      }
      if (match.awayTeam.backendId != null) {
        await ApiService.submitTeamMatchStats(
          matchId: match.backendId!,
          teamId:  match.awayTeam.backendId!,
          goals:   match.awayTeamScore ?? 0,
          passes:  0, fouls: 0, corners: 0,
        );
      }
    } catch (e) {
      debugPrint('❌ [Sync Stats] Error: $e');
    }
  }
}
