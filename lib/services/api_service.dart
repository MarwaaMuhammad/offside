import 'dart:convert';
import 'package:http/http.dart' as http;

/// Central class for all communication with the Offside backend.
class ApiService {
  static const String baseUrl =
      'https://offside-graduation-project-production.up.railway.app';

  static Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static dynamic _handleResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    } else {
      throw ApiException(
        statusCode: res.statusCode,
        message: _extractErrorMessage(res.body),
      );
    }
  }

  static String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded['detail'] ?? decoded['message'] ?? body;
    } catch (_) {
      return body;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  TOURNAMENTS
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createTournament({
    required String name,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final body = {
      'tournament_name': name,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
    };
    final res = await http.post(_uri('/tournaments'), headers: _headers, body: jsonEncode(body));
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getTournaments() async {
    final res = await http.get(_uri('/tournaments'), headers: _headers);
    return _handleResponse(res);
  }

  // ═══════════════════════════════════════════════════════════════
  //  TEAMS
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createTeam({
    required String name,
    String? primaryColor,
    String? secondaryColor,
    List<String>? playerNames,
  }) async {
    final body = {
      'team_name': name,
      if (primaryColor != null) 'primary_tshirt_color': primaryColor,
      if (secondaryColor != null) 'secondary_tshirt_color': secondaryColor,
      if (playerNames != null) 'player_names_list': playerNames,
    };
    final res = await http.post(_uri('/teams'), headers: _headers, body: jsonEncode(body));
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getTeams() async {
    final res = await http.get(_uri('/teams'), headers: _headers);
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getTeamById(String teamId) async {
    final res = await http.get(_uri('/teams/$teamId'), headers: _headers);
    return _handleResponse(res);
  }

  // ═══════════════════════════════════════════════════════════════
  //  PLAYERS
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createPlayer({
    required String teamId,
    required String fullName,
    required int jerseyNumber,
    required String nationality,
    required double height,
    required double weight,
    required String position,
    double highestSpeed = 0.0,
    double totalDestination = 0.0,
  }) async {
    final body = {
      'team_id': teamId,
      'full_name': fullName,
      'jersey_number': jerseyNumber,
      'nationality': nationality,
      'height': height,
      'weight': weight,
      'position': position,
      'highest_speed': highestSpeed,
      'total_destination': totalDestination,
    };
    final res = await http.post(_uri('/players'), headers: _headers, body: jsonEncode(body));
    return _handleResponse(res);
  }

  // ═══════════════════════════════════════════════════════════════
  //  MATCHES
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createMatch({
    required String tournamentId,
    required DateTime matchDate,
    String? videoUrl,
  }) async {
    final body = {
      'tournament_id': tournamentId,
      'match_date': matchDate.toIso8601String(),
      if (videoUrl != null) 'video_url': videoUrl,
    };
    final res = await http.post(_uri('/matches'), headers: _headers, body: jsonEncode(body));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateMatch(
    String matchId, {
    int? scoreTeamA,
    int? scoreTeamB,
    String? status,
    String? winnerId,
    DateTime? endTime,
  }) async {
    final body = <String, dynamic>{
      if (scoreTeamA != null) 'score_teamA': scoreTeamA,
      if (scoreTeamB != null) 'score_teamB': scoreTeamB,
      if (status != null) 'status': status,
      if (winnerId != null) 'winner_team_id': winnerId,
      if (endTime != null) 'end_time': endTime.toIso8601String(),
    };
    final res = await http.patch(
      _uri('/matches/$matchId'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  // ═══════════════════════════════════════════════════════════════
  //  STATS
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> submitMatchStats({
    required String matchId,
    required String teamId,
    int passesCount = 0,
    int goalCount = 0,
    int foulCount = 0,
    int yellowCardCount = 0,
    int redCardCount = 0,
    int goalkeeperSaves = 0,
    int cornerCount = 0,
    String? mvpName,
    int ownGoals = 0,
    int freeKicks = 0,
  }) async {
    final body = {
      'match_id': matchId,
      'team_id': teamId,
      'passes_count': passesCount,
      'goal_count': goalCount,
      'foul_count': foulCount,
      'yellow_card_count': yellowCardCount,
      'red_card_count': redCardCount,
      'goalkeeper_saves': goalkeeperSaves,
      'corner_count': cornerCount,
      if (mvpName != null) 'mvp_name': mvpName,
      'own_goals': ownGoals,
      'free_kicks': freeKicks,
    };
    final res = await http.post(_uri('/match-stats'), headers: _headers, body: jsonEncode(body));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> submitPlayerStats({
    required String playerId,
    String? heatmapImageUrl,
    required String position,
    int appearanceCount = 0,
  }) async {
    final body = {
      'player_id': playerId,
      'heatmap_image_url': heatmapImageUrl,
      'position': position,
      'appearance_count': appearanceCount,
    };
    final res = await http.post(_uri('/player-stats'), headers: _headers, body: jsonEncode(body));
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> submitTeamStats({
    required String teamId,
    int appearanceCount = 0,
    int totalOwnGoals = 0,
  }) async {
    final body = {
      'team_id': teamId,
      'appearance_count': appearanceCount,
      'total_own_goals': totalOwnGoals,
    };
    final res = await http.post(_uri('/team-stats'), headers: _headers, body: jsonEncode(body));
    return _handleResponse(res);
  }

  // Legacy/Compatibility methods (if needed by other pages)
  static Future<Map<String, dynamic>> submitTeamMatchStats({
    required String matchId,
    required String teamId,
    required int goals,
    required int shots,
    required int passes,
    required int fouls,
    required int yellowCards,
    required int redCards,
    required int offsides,
    required int corners,
  }) async {
    return submitMatchStats(
      matchId: matchId,
      teamId: teamId,
      goalCount: goals,
      passesCount: passes,
      foulCount: fouls,
      yellowCardCount: yellowCards,
      redCardCount: redCards,
      cornerCount: corners,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'ApiException [$statusCode]: $message';
}
