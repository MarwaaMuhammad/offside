import 'package:flutter/material.dart';
import 'package:offside/services/api_service.dart';

/// A temporary debug screen you can push from anywhere to verify
/// the backend connection is working.
///
/// USAGE (in any page, temporarily):
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiTestPage()));
///
/// DELETE this file once everything is confirmed working.
class ApiTestPage extends StatefulWidget {
  const ApiTestPage({super.key});

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  final List<String> _log = [];
  bool _loading = false;

  void _addLog(String msg) {
    setState(() => _log.insert(0, "${DateTime.now().toIso8601String().substring(11, 19)}  $msg"));
  }

  // ── TEST 1: GET /tournaments ─────────────────────────────────────
  Future<void> _testGetTournaments() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getTournaments();
      _addLog("✅ GET /tournaments → ${result.length} items");
      if (result.isNotEmpty) _addLog("   First: ${result.first}");
    } on ApiException catch (e) {
      _addLog("❌ ${e.statusCode}: ${e.message}");
    } catch (e) {
      _addLog("❌ $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── TEST 2: POST /tournaments ────────────────────────────────────
  Future<void> _testCreateTournament() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.createTournament(
        name: "Test League ${DateTime.now().millisecondsSinceEpoch}",
      );
      _addLog("✅ POST /tournaments → id: ${result['id']}");
    } on ApiException catch (e) {
      _addLog("❌ ${e.statusCode}: ${e.message}");
    } catch (e) {
      _addLog("❌ $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── TEST 3: POST /teams ──────────────────────────────────────────
  Future<void> _testCreateTeam() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.createTeam(name: "Test Team Alpha");
      _addLog("✅ POST /teams → id: ${result['id']}");
    } on ApiException catch (e) {
      _addLog("❌ ${e.statusCode}: ${e.message}");
    } catch (e) {
      _addLog("❌ $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── TEST 4: GET /teams ───────────────────────────────────────────
  Future<void> _testGetTeams() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getTeams();
      _addLog("✅ GET /teams → ${result.length} teams");
    } on ApiException catch (e) {
      _addLog("❌ ${e.statusCode}: ${e.message}");
    } catch (e) {
      _addLog("❌ $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1126),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16246E),
        title: const Text("🛠️ Backend Connection Test",
            style: TextStyle(color: Colors.white)),
        leading: BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Status banner ──────────────────────────────────────
          Container(
            width: double.infinity,
            color: const Color(0xFF1C2C7A),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(
              "Base URL: ${ApiService.baseUrl}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),

          // ── Test buttons ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn("GET tournaments", _testGetTournaments, Colors.teal),
                _btn("POST tournament", _testCreateTournament, Colors.blue),
                _btn("GET teams", _testGetTeams, Colors.orange),
                _btn("POST team", _testCreateTeam, Colors.purple),
                _btn("Clear log", () => setState(() => _log.clear()), Colors.red),
              ],
            ),
          ),

          if (_loading)
            const LinearProgressIndicator(
              backgroundColor: Colors.white12,
              color: Colors.tealAccent,
            ),

          // ── Log output ─────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _log.isEmpty
                  ? const Center(
                      child: Text(
                        "Tap a button above to test the backend",
                        style: TextStyle(color: Colors.white38),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _log.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          _log[i],
                          style: TextStyle(
                            color: _log[i].startsWith("✅")
                                ? Colors.greenAccent
                                : _log[i].startsWith("❌")
                                    ? Colors.redAccent
                                    : Colors.white70,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap, Color color) {
    return ElevatedButton(
      onPressed: _loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }
}
