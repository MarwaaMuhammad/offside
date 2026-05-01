import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://gsvowvzdxphlguclawur.supabase.co/rest/v1';
  static const String supabaseAnonKey = "sb_publishable_vuHhBKjf4kJJgPnkFlNm9A_ErI2gVd_"; 

  static Uri _uri(String path, {Map<String, String>? queryParameters}) {
    String cleanPath = path.startsWith('/') ? path : '/$path';
    if (cleanPath.endsWith('/')) {
      cleanPath = cleanPath.substring(0, cleanPath.length - 1);
    }
    
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final queryString = queryParameters.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      return Uri.parse('$baseUrl$cleanPath?$queryString');
    }
    
    return Uri.parse('$baseUrl$cleanPath');
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'Prefer': 'return=representation',
  };

  static dynamic _handleResponse(http.Response res) {
    print("📡 [API Response] ${res.statusCode} | ${res.body}");
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is List && decoded.isNotEmpty) return decoded.first;
      return decoded;
    } else {
      throw ApiException(statusCode: res.statusCode, message: res.body);
    }
  }

  // 1. Tournament Creation & Fetching
  static Future<Map<String, dynamic>> createTournament({
    required String name, 
    required DateTime startDate, 
    required DateTime endDate
  }) async {
    final res = await http.post(
      _uri('TOURNAMENTS'), 
      headers: _headers, 
      body: jsonEncode({
        'tournament_name': name, 
        'start_date': startDate.toIso8601String(), 
        'end_date': endDate.toIso8601String()
      })
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> fetchTournaments() async {
    final res = await http.get(_uri('TOURNAMENTS'), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(statusCode: res.statusCode, message: res.body);
  }

  // 2. Team Creation & Fetching
  static Future<Map<String, dynamic>> createTeam({
    required String name, 
    required String primaryColor, 
    required String secondaryColor,
    required String goalkeeperColor,
  }) async {
    final res = await http.post(
      _uri('TEAMS'), 
      headers: _headers, 
      body: jsonEncode({
        'team_name': name, 
        'primary_tshirt_colors': primaryColor, 
        'secondary _tshirt_colors': secondaryColor,
        'goalkeeper_tshirt_colors': goalkeeperColor,
      })
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> fetchTeams() async {
    final res = await http.get(_uri('TEAMS'), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(statusCode: res.statusCode, message: res.body);
  }

  // 3. Match Creation & Fetching
  static Future<Map<String, dynamic>> createMatch({
    required dynamic tournamentId, 
    required dynamic homeTeamId, 
    required dynamic awayTeamId, 
    required DateTime matchDate, 
    String? videoUrl
  }) async {
    final res = await http.post(
      _uri('MATCHES'), 
      headers: _headers, 
      body: jsonEncode({
        'tournament_id': int.tryParse(tournamentId.toString()) ?? tournamentId, 
        'home_team_id': int.tryParse(homeTeamId.toString()) ?? homeTeamId, 
        'away_team_id': int.tryParse(awayTeamId.toString()) ?? awayTeamId, 
        'match_date': matchDate.toIso8601String(), 
        'video_url': videoUrl ?? ""
      })
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> fetchMatches() async {
    final res = await http.get(_uri('MATCHES'), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(statusCode: res.statusCode, message: res.body);
  }

  // 4. User Creation
  static Future<Map<String, dynamic>> createUser({
    required String name, 
    required String email, 
    required String nationality, 
    required String phoneNumber
  }) async {
    final res = await http.post(
      _uri('USERS'), 
      headers: _headers, 
      body: jsonEncode({
        'name': name, 
        'email': email, 
        'nationality': nationality, 
        'phone_number': phoneNumber
      })
    );
    return _handleResponse(res);
  }

  // 5. Submit Team Stats
  static Future<Map<String, dynamic>> submitTeamStats({
    required dynamic matchId, 
    required dynamic teamId, 
    required int goals, 
    required int passes, 
    required int fouls, 
    required int corners
  }) async {
    final res = await http.post(
      _uri('TEAM_MATCH_STATS'), 
      headers: _headers, 
      body: jsonEncode({
        'match_id': int.tryParse(matchId.toString()) ?? matchId, 
        'team_id': int.tryParse(teamId.toString()) ?? teamId, 
        'goals': goals, 
        'passes': passes, 
        'foul': fouls, 
        'corner': corners
      })
    );
    return _handleResponse(res);
  }

  // 6. Submit Player Stats
  static Future<Map<String, dynamic>> submitPlayerStats({
    required dynamic matchId, 
    required dynamic playerId, 
    required int goals, 
    required int assists, 
    required int yellowCard, 
    required int redCard, 
    required double topSpeed, 
    required double totalDistance
  }) async {
    final res = await http.post(
      _uri('PLAYER_MATCH_STATS'), 
      headers: _headers, 
      body: jsonEncode({
        'match_id': int.tryParse(matchId.toString()) ?? matchId, 
        'player_id': int.tryParse(playerId.toString()) ?? playerId, 
        'goals': goals, 
        'assists': assists, 
        'yellow_card': yellowCard, 
        'red_card': redCard, 
        'top_speed': topSpeed, 
        'total_distance': totalDistance
      })
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> getAllPlayers() async {
    final res = await http.get(_uri('PLAYERS'), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw ApiException(statusCode: res.statusCode, message: res.body);
  }

  static Future<Map<String, dynamic>> createPlayer({
    required String fullName, 
    required int jerseyNumber, 
    required String nationality, 
    required double height, 
    required double weight, 
    required String position, 
    required String email, 
    required String phoneNumber, 
    dynamic teamId
  }) async {
    final res = await http.post(
      _uri('PLAYERS'), 
      headers: _headers, 
      body: jsonEncode({
        'full_name': fullName, 
        'jersey_number': jerseyNumber, 
        'nationality': nationality, 
        'height': height, 
        'weight': weight, 
        'position': position, 
        'email': email, 
        'phone_number': phoneNumber, 
        if (teamId != null) 'team_id': int.tryParse(teamId.toString()) ?? teamId
      })
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updatePlayer({
    required String playerId,
    int? jerseyNumber,
    dynamic teamId,
  }) async {
    final parsedPlayerId = int.tryParse(playerId) ?? playerId;
    final parsedTeamId = teamId != null ? (int.tryParse(teamId.toString()) ?? teamId) : null;

    final res = await http.patch(
      _uri('PLAYERS', queryParameters: {'player_id': 'eq.$parsedPlayerId'}),
      headers: _headers,
      body: jsonEncode({
        if (jerseyNumber != null) 'jersey_number': jerseyNumber,
        if (parsedTeamId != null) 'team_id': parsedTeamId,
      })
    );
    return _handleResponse(res);
  }

  static Future<bool> ping() async {
    try {
      final res = await http.get(_uri('PLAYERS'), headers: _headers).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> sendInvitation({
    required dynamic teamId,
    required dynamic playerId,
  }) async {
    final res = await http.post(
      _uri('INVITATIONS'), 
      headers: _headers, 
      body: jsonEncode({
        'team_id': int.tryParse(teamId.toString()) ?? teamId,
        'player_id': int.tryParse(playerId.toString()) ?? playerId,
        'status': 'pending',
      })
    );
    return _handleResponse(res);
  }

  static Future<void> updateInvitationStatus(dynamic inviteId, String status) async {
    final parsedInviteId = int.tryParse(inviteId.toString()) ?? inviteId;
    final res = await http.patch(
      _uri('INVITATIONS', queryParameters: {'invitation_id': 'eq.$parsedInviteId'}),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    _handleResponse(res);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'Error $statusCode: $message';
}
