import 'dart:convert';
import 'package:http/http.dart' as http;

/// Central class for all communication with the Offside backend.
/// Base URL: https://offside-graduation-project-production.up.railway.app
class ApiService {
  static const String baseUrl =
      'https://offside-graduation-project-production.up.railway.app';

  // ─────────────────────────────────────────────────
  //  Helper: build URI
  // ─────────────────────────────────────────────────
  static Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  // ─────────────────────────────────────────────────
  //  Helper: shared headers
  // ─────────────────────────────────────────────────
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ─────────────────────────────────────────────────
  //  Helper: response handler
  // ─────────────────────────────────────────────────
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
  //  TEAMS
  // ═══════════════════════════════════════════════════════════════

  /// Create a new team. Returns the created team as a Map.
  static Future<Map<String, dynamic>> createTeam({
    required String name,
  }) async {
    final res = await http.post(
      _uri('/teams'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    return _handleResponse(res);
  }

  /// Fetch all teams.
  static Future<List<dynamic>> getTeams() async {
    final res = await http.get(_uri('/teams'), headers: _headers);
    return _handleResponse(res);
  }

  /// Fetch a single team by its ID.
  static Future<Map<String, dynamic>> getTeamById(String teamId) async {
    final res = await http.get(_uri('/teams/$teamId'), headers: _headers);
    return _handleResponse(res);
  }

  // ═══════════════════════════════════════════════════════════════
  //  MATCHES
  // ═══════════════════════════════════════════════════════════════

  /// Create a new match (fixture).
  static Future<Map<String, dynamic>> createMatch({
    required String tournamentId,
    required String teamAId,
    required String teamBId,
    required DateTime startTime,
    DateTime? endTime,
    String status = 'scheduled', // scheduled | live | finished
    String? venueId,
  }) async {
    final body = {
      'tournament_id': tournamentId,
      'teamA_id': teamAId,
      'teamB_id': teamBId,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime.toIso8601String(),
      'status': status,
      'score_teamA': 0,
      'score_teamB': 0,
      if (venueId != null) 'venue_id': venueId,
    };
    final res = await http.post(
      _uri('/matches'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  /// Fetch all matches, optionally filtered by tournament or status.
  static Future<List<dynamic>> getMatches({
    String? tournamentId,
    String? status,
  }) async {
    final query = <String, String>{
      if (tournamentId != null) 'tournament_id': tournamentId,
      if (status != null) 'status': status,
    };
    final res = await http.get(_uri('/matches', query), headers: _headers);
    return _handleResponse(res);
  }

  /// Fetch a single match by ID.
  static Future<Map<String, dynamic>> getMatchById(String matchId) async {
    final res = await http.get(_uri('/matches/$matchId'), headers: _headers);
    return _handleResponse(res);
  }

  /// Update a match's score and/or status.
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
  //  TEAM MATCH STATS
  // ═══════════════════════════════════════════════════════════════

  /// Submit or update stats for one team in a match.
  static Future<Map<String, dynamic>> submitTeamMatchStats({
    required String matchId,
    required String teamId,
    required int goals,
    required int shots,
    int shotsOnTarget = 0,
    double possession = 0.0,
    required int passes,
    double passAccuracy = 0.0,
    required int fouls,
    required int yellowCards,
    required int redCards,
    required int offsides,
    required int corners,
    int saves = 0,
    double distanceCovered = 0.0,
  }) async {
    final body = {
      'match_id': matchId,
      'team_id': teamId,
      'goals': goals,
      'shots': shots,
      'shots_on_target': shotsOnTarget,
      'possession': possession,
      'passes': passes,
      'pass_accuracy': passAccuracy,
      'fouls': fouls,
      'yellow_cards': yellowCards,
      'red_cards': redCards,
      'offsides': offsides,
      'corners': corners,
      'saves': saves,
      'distance_covered': distanceCovered,
    };
    final res = await http.post(
      _uri('/team-match-stats'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  /// Fetch stats for a specific match (returns stats for both teams).
  static Future<List<dynamic>> getMatchStats(String matchId) async {
    final res = await http.get(
      _uri('/team-match-stats', {'match_id': matchId}),
      headers: _headers,
    );
    return _handleResponse(res);
  }

  // ═══════════════════════════════════════════════════════════════
  //  TOURNAMENTS (needed to create a league on the backend)
  // ═══════════════════════════════════════════════════════════════

  /// Create a tournament (maps to your local "League").
  static Future<Map<String, dynamic>> createTournament({
    required String name,
    String? description,
  }) async {
    final res = await http.post(
      _uri('/tournaments'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        if (description != null) 'description': description,
      }),
    );
    return _handleResponse(res);
  }

  /// Get all tournaments.
  static Future<List<dynamic>> getTournaments() async {
    final res = await http.get(_uri('/tournaments'), headers: _headers);
    return _handleResponse(res);
  }
}

// ─────────────────────────────────────────────────
//  Custom Exception
// ─────────────────────────────────────────────────
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException [$statusCode]: $message';
}
