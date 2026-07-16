import 'package:flutter/material.dart';
import '../models/match_state.dart';
import '../theme/app_theme.dart';
import '../widgets/scoreboard_widgets.dart';

class TossScreen extends StatefulWidget {
  final MatchState state;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const TossScreen({
    super.key,
    required this.state,
    required this.onStart,
    required this.onBack,
  });

  @override
  State<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends State<TossScreen> {
  String winner = 'A';
  String decision = 'bat';

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        SectionCard(
          title: 'Toss',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Who won the toss?', style: AppTextStyles.small),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                dropdownColor: AppColors.panel2,
                value: winner,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 'A', child: Text(s.teamA.name)),
                  DropdownMenuItem(value: 'B', child: Text(s.teamB.name)),
                ],
                onChanged: (v) => setState(() => winner = v ?? winner),
              ),
              const SizedBox(height: 12),
              const Text('Choose to', style: AppTextStyles.small),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: decision == 'bat'
                        ? ElevatedButton(
                        onPressed: () => setState(() => decision = 'bat'),
                        child: const Text('🏏 Bat first'))
                        : OutlinedButton(
                        onPressed: () => setState(() => decision = 'bat'),
                        child: const Text('🏏 Bat first')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: decision == 'bowl'
                        ? ElevatedButton(
                        onPressed: () => setState(() => decision = 'bowl'),
                        child: const Text('⚾ Bowl first'))
                        : OutlinedButton(
                        onPressed: () => setState(() => decision = 'bowl'),
                        child: const Text('⚾ Bowl first')),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              s.tossWinner = winner;
              s.tossDecision = decision;
              s.battingTeam = decision == 'bat' ? winner : (winner == 'A' ? 'B' : 'A');
              s.bowlingTeam = s.battingTeam == 'A' ? 'B' : 'A';
              widget.onStart();
            },
            child: const Text('Start match ▶'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(onPressed: widget.onBack, child: const Text('◀ Back')),
        ),
      ],
    );
  }
}