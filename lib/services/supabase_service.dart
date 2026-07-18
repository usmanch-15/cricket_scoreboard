import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Thin wrapper around the Supabase client. Every match row is scoped to
/// the signed-in (anonymous) user via `user_id`, and enforced server-side
/// by RLS policies — so one device can never see, edit, or delete another
/// device's matches, even if someone tampers with the client code.
class SupabaseService {
  static const String _table = 'cricket_matches';

  static SupabaseClient get _client => Supabase.instance.client;

  /// Call once, before runApp(). Signs the device in anonymously so we
  /// get a stable auth.uid() to scope all data to.
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
  }

  static String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError(
          'Not signed in yet — SupabaseService.init() must complete first.');
    }
    return id;
  }

  /// Creates or overwrites the row for this match id with the given
  /// state JSON, tagged with the current device's user id.
  static Future<void> saveMatch(String matchId, Map<String, dynamic> stateJson) async {
    await _client.from(_table).upsert({
      'id': matchId,
      'user_id': _userId,
      'state': stateJson,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Returns the saved state JSON for this match id, or null if there
  /// isn't one yet, or it doesn't belong to this device.
  static Future<Map<String, dynamic>?> loadMatch(String matchId) async {
    final row = await _client
        .from(_table)
        .select('state')
        .eq('id', matchId)
        .eq('user_id', _userId)
        .maybeSingle();
    if (row == null) return null;
    return row['state'] as Map<String, dynamic>;
  }

  static Future<void> deleteMatch(String matchId) async {
    await _client.from(_table).delete().eq('id', matchId).eq('user_id', _userId);
  }

  /// Returns every match saved by *this device only* (most recently
  /// updated first) — used by the match history screen.
  static Future<List<Map<String, dynamic>>> fetchAllMatches({int limit = 50}) async {
    final rows = await _client
        .from(_table)
        .select('id, state, updated_at')
        .eq('user_id', _userId)
        .order('updated_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}