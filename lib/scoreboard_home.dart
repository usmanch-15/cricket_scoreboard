import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'models/match_state.dart';
import 'theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/toss_screen.dart';
import 'screens/openers_screen.dart';
import 'screens/match_screen.dart';
import 'screens/result_screen.dart';

/// Only the *match id* is kept locally (tiny string) — the full match
/// state itself lives in Supabase. This lets a device "remember" which
/// row is its own current match across app restarts, with no login.
const _matchIdKey = 'cricket_scoreboard_match_id_v1';

enum _Screen { home, setup, toss, openers, match, result }

class ScoreboardHome extends StatefulWidget {
  const ScoreboardHome({super.key});

  @override
  State<ScoreboardHome> createState() => _ScoreboardHomeState();
}

class _ScoreboardHomeState extends State<ScoreboardHome> {
  MatchState state = MatchState();
  _Screen screen = _Screen.home;
  bool _loaded = false;
  String? _matchId;
  String? _loadError;

  /// If the saved match is unfinished, this remembers which screen it
  /// was left on so the Home screen's "Resume" button can jump straight
  /// back there — without ever auto-opening it on launch.
  _Screen? _resumeScreen;
  String? _resumeStageLabel;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    var matchId = prefs.getString(_matchIdKey);
    matchId ??= const Uuid().v4();
    await prefs.setString(_matchIdKey, matchId);
    _matchId = matchId;

    _resumeScreen = null;
    _resumeStageLabel = null;

    try {
      final json = await SupabaseService.loadMatch(matchId);
      if (json != null) {
        final loadedState = MatchState.fromJson(json);
        if (!loadedState.matchOver) {
          // Keep the loaded match available to resume, but the app
          // always opens on Home first — never straight into it.
          state = loadedState;
          if (state.battingTeam != null && state.striker != null) {
            _resumeScreen = _Screen.match;
            _resumeStageLabel = 'Innings ${state.innings}, ${state.score}/${state.wickets}';
          } else if (state.battingTeam != null) {
            _resumeScreen = _Screen.openers;
            _resumeStageLabel = 'Selecting openers';
          } else if (state.tossWinner != null) {
            _resumeScreen = _Screen.toss;
            _resumeStageLabel = 'Toss done';
          } else {
            _resumeScreen = _Screen.setup;
            _resumeStageLabel = 'Team setup';
          }
        }
        // If the saved match is already finished, it lives in History —
        // Home starts with a clean slate ready for "Create New Match".
      }
      _loadError = null;
    } catch (e) {
      // Common cause: SupabaseConfig.url / anonKey haven't been filled in
      // yet, or the cricket_matches table doesn't exist (run schema.sql).
      _loadError = e.toString();
    }

    screen = _Screen.home;
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    if (_matchId == null) return;
    try {
      await SupabaseService.saveMatch(_matchId!, state.toJson());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save to Supabase: $e')),
        );
      }
    }
  }

  /// Starts a brand new match: fresh state + a brand new match id, so
  /// nothing from any previous (even unfinished) match carries over.
  /// The old match, if any, stays safely in History.
  Future<void> _createNewMatch() async {
    final prefs = await SharedPreferences.getInstance();
    final newId = const Uuid().v4();
    await prefs.setString(_matchIdKey, newId);
    _matchId = newId;

    setState(() {
      state = MatchState();
      _resumeScreen = null;
      _resumeStageLabel = null;
      screen = _Screen.setup;
    });
  }

  void _resumeMatch() {
    if (_resumeScreen == null) return;
    setState(() => screen = _resumeScreen!);
  }

  Future<void> _resetAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Pura match reset ho jayega. Confirm?',
            style: TextStyle(color: AppColors.text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirm != true) return;

    // Start a brand new match row so old results/history stay in Supabase,
    // then send the user back to Home rather than straight into a new one.
    final prefs = await SharedPreferences.getInstance();
    final newId = const Uuid().v4();
    await prefs.setString(_matchIdKey, newId);
    _matchId = newId;

    setState(() {
      state = MatchState();
      _resumeScreen = null;
      _resumeStageLabel = null;
      screen = _Screen.home;
    });
  }

  /// Called when a match finishes naturally (not via the reset button).
  /// The finished match is safe in Supabase/History, so Home no longer
  /// offers to "resume" it.
  void _goHomeAfterMatchEnd() {
    setState(() {
      _resumeScreen = null;
      _resumeStageLabel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SplashScreen();
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, color: AppColors.red, size: 40),
                const SizedBox(height: 12),
                const Text('Could not connect to Supabase.',
                    style: TextStyle(color: AppColors.text, fontSize: 16)),
                const SizedBox(height: 8),
                Text(_loadError!,
                    style: AppTextStyles.small, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text(
                  'Check lib/config/supabase_config.dart has your project '
                      'URL + anon key, and that supabase/schema.sql has been run.',
                  style: AppTextStyles.small,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _loaded = false;
                    _restore();
                  }),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget body;
    switch (screen) {
      case _Screen.home:
        body = HomeScreen(
          resumableState: _resumeScreen != null ? state : null,
          resumeStageLabel: _resumeStageLabel,
          onCreateNew: _createNewMatch,
          onResume: _resumeMatch,
          onOpenHistory: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
        );
        break;
      case _Screen.setup:
        body = SetupScreen(
          state: state,
          onChanged: _save,
          onContinue: () {
            setState(() => screen = _Screen.toss);
            _save();
          },
        );
        break;
      case _Screen.toss:
        body = TossScreen(
          state: state,
          onStart: () {
            setState(() => screen = _Screen.openers);
            _save();
          },
          onBack: () => setState(() => screen = _Screen.setup),
        );
        break;
      case _Screen.openers:
        body = OpenersScreen(
          state: state,
          onConfirm: () {
            setState(() => screen = _Screen.match);
            _save();
          },
        );
        break;
      case _Screen.match:
        body = MatchScreen(
          state: state,
          onChanged: _save,
          onInningsEnd: () => setState(() => screen = _Screen.openers),
          onMatchEnd: () {
            _goHomeAfterMatchEnd();
            setState(() => screen = _Screen.result);
          },
          onReset: _resetAll,
        );
        break;
      case _Screen.result:
        body = ResultScreen(state: state, onNewMatch: _resetAll);
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text('🏏 Cricket Scoreboard'),
        leading: screen != _Screen.home
            ? IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
          onPressed: () => setState(() => screen = _Screen.home),
        )
            : null,
        actions: [
          IconButton(
            tooltip: 'Match history',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}