import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

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
    debugPrint("📡 [API Response] ${res.statusCode} | ${res.body}");
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is List && decoded.isNotEmpty) return decoded.first;
      return decoded;
    } else {
      throw ApiException(statusCode: res.statusCode, message: res.body);
    }
  }

  static dynamic _handleListResponse(http.Response res) {
    debugPrint("📡 [API List Response] ${res.statusCode}");
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    } else {
      throw ApiException(statusCode: res.statusCode, message: res.body);
    }
  }

  // --- USER & PLAYER DATA FETCHING ---

  /// Fetches user/player profile data.
  /// First checks the PLAYERS table, then the USERS table.
  static Future<Map<String, dynamic>?> fetchUserData(String email) async {
    final trimmedEmail = email.trim().toLowerCase();
    debugPrint("🔍 [API] Fetching profile for: $trimmedEmail");
    
    try {
      // 1. Check PLAYERS table using Supabase Client
      debugPrint("🔍 [API] Checking PLAYERS table...");
      final playerRes = await Supabase.instance.client
          .from('PLAYERS')
          .select()
          .ilike('email', trimmedEmail)
          .maybeSingle();
      
      if (playerRes != null) {
        final data = Map<String, dynamic>.from(playerRes);
        data['role'] = 'player';
        debugPrint("✅ [API] Found record in PLAYERS table");
        return data;
      }

      // 2. Check USERS table using Supabase Client
      debugPrint("🔍 [API] Record not found in PLAYERS. Checking USERS table...");
      final userRes = await Supabase.instance.client
          .from('USERS')
          .select()
          .ilike('email', trimmedEmail)
          .maybeSingle();

      if (userRes != null) {
        final data = Map<String, dynamic>.from(userRes);
        data['role'] = 'user';
        debugPrint("✅ [API] Found record in USERS table");
        return data;
      }
      
      debugPrint("⚠️ [API] No record found in PLAYERS or USERS for email: $trimmedEmail");
      return null;
    } catch (e) {
      debugPrint("❌ [API] fetchUserData error: $e");
      // Fallback to raw HTTP if client fails for any reason
      return _fetchUserDataFallback(trimmedEmail);
    }
  }

  /// Fallback method using raw HTTP in case Supabase client has issues
  static Future<Map<String, dynamic>?> _fetchUserDataFallback(String email) async {
    debugPrint("🔄 [API] Attempting fallback fetch for: $email");
    try {
      final playerRes = await http.get(
        _uri('PLAYERS', queryParameters: {'email': 'ilike.$email'}),
        headers: _headers,
      );
      final playerData = _handleListResponse(playerRes);
      if (playerData is List && playerData.isNotEmpty) {
        final data = Map<String, dynamic>.from(playerData.first);
        data['role'] = 'player';
        return data;
      }

      final userRes = await http.get(
        _uri('USERS', queryParameters: {'email': 'ilike.$email'}),
        headers: _headers,
      );
      final userData = _handleListResponse(userRes);
      if (userData is List && userData.isNotEmpty) {
        final data = Map<String, dynamic>.from(userData.first);
        data['role'] = 'user';
        return data;
      }
    } catch (e) {
      debugPrint("❌ [API] Fallback fetch failed: $e");
    }
    return null;
  }

  static Future<void> updateUserProfile({
    required String email,
    required String role,
    required Map<String, dynamic> updates,
  }) async {
    final table = role == 'player' ? 'PLAYERS' : 'USERS';
    debugPrint("📤 [API] Updating $table for $email");
    
    try {
      await Supabase.instance.client
          .from(table)
          .update(updates)
          .ilike('email', email.trim());
      debugPrint("✅ [API] Update successful");
    } catch (e) {
      debugPrint("❌ [API] Update error: $e");
      // Fallback to raw HTTP
      final res = await http.patch(
        _uri(table, queryParameters: {'email': 'ilike.${email.trim()}'}),
        headers: _headers,
        body: jsonEncode(updates),
      );
      _handleResponse(res);
    }
  }

  // Set this to your Supabase storage bucket name (e.g., 'avatars', 'profile_images', etc.)
  static const String _storageBucket = 'avatars'; 

  static Future<String?> uploadProfileImage(File file, String userId) async {
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'profile_images/$fileName';
    
    debugPrint("📤 [API] Uploading image to bucket: $_storageBucket");
    try {
      await Supabase.instance.client.storage
          .from(_storageBucket)
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      final imageUrl = Supabase.instance.client.storage
          .from(_storageBucket)
          .getPublicUrl(path);
      
      debugPrint("✅ [API] Image upload successful: $imageUrl");
      return imageUrl;
    } catch (e) {
      debugPrint("❌ [API] Image upload error: $e");
      if (e.toString().contains('Bucket not found')) {
        throw Exception("Storage bucket '$_storageBucket' not found. Please create it in your Supabase project.");
      }
      rethrow;
    }
  }

  // --- TOURNAMENTS & LEAGUES ---

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
    return _handleListResponse(res);
  }

  // --- TEAMS ---

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
    return _handleListResponse(res);
  }

  // --- MATCHES ---

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
    return _handleListResponse(res);
  }

  // --- USERS ---

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

  // --- STATS ---

  static Future<Map<String, dynamic>> submitTeamMatchStats({
    required dynamic matchId, 
    required dynamic teamId, 
    required int goals, 
    required int passes, 
    required int fouls, 
    required int corners,
    double acquisitionAvg = 0.0,
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
        'corner': corners,
        'acquisition_avg': acquisitionAvg,
      })
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> fetchTeamMatchStats() async {
    final res = await http.get(_uri('TEAM_MATCH_STATS'), headers: _headers);
    return _handleListResponse(res);
  }

  static Future<Map<String, dynamic>> submitPlayerMatchStats({
    required dynamic matchId, 
    required dynamic playerId, 
    required int goals, 
    required int assists, 
    required int yellowCard, 
    required int redCard, 
    required double topSpeed, 
    required double totalDistance,
    bool isMvp = false,
    double acquisition = 0.0,
    String? heatmapImageUrl,
    Map<String, dynamic>? actionsDetected,
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
        'total_distance': totalDistance,
        'is_mvp': isMvp,
        'acquisition': acquisition,
        'heatmap_image_url': heatmapImageUrl,
        'actions_detected': actionsDetected,
      })
    );
    return _handleResponse(res);
  }

  static Future<List<dynamic>> fetchPlayerMatchStats() async {
    final res = await http.get(_uri('PLAYER_MATCH_STATS'), headers: _headers);
    return _handleListResponse(res);
  }

  // --- PLAYERS ---

  static Future<List<dynamic>> getAllPlayers() async {
    final res = await http.get(_uri('PLAYERS'), headers: _headers);
    return _handleListResponse(res);
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

  // --- INVITATIONS ---

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
