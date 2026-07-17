import 'package:flutter/material.dart';
import '../models/match_state.dart';
import '../theme/app_theme.dart';

/// The very first screen the user sees after the splash screen. The app
/// never auto-opens straight into a match — the user must explicitly
/// tap "Create new match" (or "Resume" a match they left mid-way).
class HomeScreen extends StatelessWidget {
  /// Non-null only if there's a saved match that isn't finished yet.
  final MatchState? resumableState;
  final String? resumeStageLabel;

  final VoidCallback onCreateNew;
  final VoidCallback onResume;
  final VoidCallback onOpenHistory;

  const HomeScreen({
    super.key,
    required this.resumableState,
    required this.resumeStageLabel,
    required this.onCreateNew,
    required this.onResume,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 30),
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.4),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Image(image: AssetImage('assets/splash/splash_logo.png')),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'CRICKET SCOREBOARD',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.amber,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Score every ball, live.',
          textAlign: TextAlign.center,
          style: AppTextStyles.small,
        ),
        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onCreateNew,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('🏏  Create New Match', style: TextStyle(fontSize: 16)),
          ),
        ),

        if (resumableState != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onResume,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(
                'Resume — ${resumableState!.teamA.name} vs ${resumableState!.teamB.name}'
                    '${resumeStageLabel != null ? '\n($resumeStageLabel)' : ''}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenHistory,
            icon: const Icon(Icons.history, size: 18),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            label: const Text('Match History'),
          ),
        ),
      ],
    );
  }
}