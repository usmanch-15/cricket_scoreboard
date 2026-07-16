import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Thin wrapper around the Supabase client. The whole match is stored as
/// one JSONB blob per row (same shape as MatchState.toJson()) — simplest
/// possible schema, no auth/login required. Each device just remembers
/// its own match's row id locally (see ScoreboardHome).
class SupabaseService {
  static const String _table = 'cricket_matches';

  static SupabaseClient get _client => Supabase.instance.client;

  /// Call once, before runApp().
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  /// Creates or overwrites the row for this match id with the given
  /// state JSON.
  static Future<void> saveMatch(String matchId, Map<String, dynamic> stateJson) async {
    await _client.from(_table).upsert({
      'id': matchId,
      'state': stateJson,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Returns the saved state JSON for this match id, or null if there
  /// isn't one yet (e.g. first ever launch).
  static Future<Map<String, dynamic>?> loadMatch(String matchId) async {
    final row = await _client
        .from(_table)
        .select('state')
        .eq('id', matchId)
        .maybeSingle();
    if (row == null) return null;
    return row['state'] as Map<String, dynamic>;
  }

  static Future<void> deleteMatch(String matchId) async {
    await _client.from(_table).delete().eq('id', matchId);
  }
}