import 'package:flutter/material.dart';
import '../models/match_state.dart';
import '../theme/app_theme.dart';
import '../widgets/scoreboard_widgets.dart';

class SetupScreen extends StatefulWidget {
  final MatchState state;
  final VoidCallback onContinue;
  final VoidCallback onChanged;

  const SetupScreen({
    super.key,
    required this.state,
    required this.onContinue,
    required this.onChanged,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final TextEditingController teamAController;
  late final TextEditingController teamBController;
  late final TextEditingController oversController;
  late final TextEditingController wicketsController;
  final playerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.state;
    teamAController = TextEditingController(text: s.teamA.name);
    teamBController = TextEditingController(text: s.teamB.name);
    oversController = TextEditingController(text: '${s.totalOvers}');
    wicketsController = TextEditingController(text: '${s.totalWickets}');
  }

  @override
  void dispose() {
    teamAController.dispose();
    teamBController.dispose();
    oversController.dispose();
    wicketsController.dispose();
    playerController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = playerController.text.trim();
    if (name.isEmpty) return;
    final s = widget.state;
    final team = s.currentPlayerTeam == 'A' ? s.teamA : s.teamB;
    if (team.players.length >= 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('11 players already added (max for one team).')),
      );
      return;
    }
    setState(() {
      team.players.add(name);
      playerController.clear();
    });
    widget.onChanged();
  }

  void _removePlayer(int index) {
    final s = widget.state;
    final team = s.currentPlayerTeam == 'A' ? s.teamA : s.teamB;
    setState(() => team.players.removeAt(index));
    widget.onChanged();
  }

  void _switchPlayerTeam() {
    final s = widget.state;
    setState(() => s.currentPlayerTeam = s.currentPlayerTeam == 'A' ? 'B' : 'A');
  }

  void _continue() {
    final s = widget.state;
    s.teamA.name = teamAController.text.trim().isEmpty ? 'Team A' : teamAController.text.trim();
    s.teamB.name = teamBController.text.trim().isEmpty ? 'Team B' : teamBController.text.trim();
    s.totalOvers = int.tryParse(oversController.text) ?? 20;
    s.totalWickets = int.tryParse(wicketsController.text) ?? 10;
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final team = s.currentPlayerTeam == 'A' ? s.teamA : s.teamB;
    final teamLabel = s.currentPlayerTeam == 'A'
        ? (teamAController.text.isEmpty ? 'Team A' : teamAController.text)
        : (teamBController.text.isEmpty ? 'Team B' : teamBController.text);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('🏏 Cricket Scoreboard',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.amber, fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Team names',
          child: Column(
            children: [
              const Align(alignment: Alignment.centerLeft, child: Text('Team A', style: AppTextStyles.small)),
              const SizedBox(height: 4),
              TextField(controller: teamAController, style: AppTextStyles.body, onChanged: (_) => setState(() {})),
              const SizedBox(height: 10),
              const Align(alignment: Alignment.centerLeft, child: Text('Team B', style: AppTextStyles.small)),
              const SizedBox(height: 4),
              TextField(controller: teamBController, style: AppTextStyles.body, onChanged: (_) => setState(() {})),
              const SizedBox(height: 10),
              const Align(alignment: Alignment.centerLeft, child: Text('Total overs', style: AppTextStyles.small)),
              const SizedBox(height: 4),
              TextField(
                controller: oversController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 10),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Wickets limit (players out)', style: AppTextStyles.small)),
              const SizedBox(height: 4),
              TextField(
                controller: wicketsController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Players — $teamLabel (optional, skip if you want)',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: playerController,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(hintText: 'Player name'),
                      onSubmitted: (_) => _addPlayer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: _addPlayer, child: const Text('Add')),
                ],
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: team.players.length,
                  itemBuilder: (ctx, i) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.panel2,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${i + 1}. ${team.players[i]}', style: AppTextStyles.body),
                          TextButton(
                            onPressed: () => _removePlayer(i),
                            style: TextButton.styleFrom(foregroundColor: AppColors.red),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _switchPlayerTeam,
                  child: const Text('Switch to next team ▶'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: _continue, child: const Text('Continue to toss ▶')),
        ),
      ],
    );
  }
}