import 'package:flutter/material.dart';
import '../models/match_state.dart';
import '../theme/app_theme.dart';
import '../widgets/scoreboard_widgets.dart';

class OpenersScreen extends StatefulWidget {
  final MatchState state;
  final VoidCallback onConfirm;

  const OpenersScreen({super.key, required this.state, required this.onConfirm});

  @override
  State<OpenersScreen> createState() => _OpenersScreenState();
}

class _OpenersScreenState extends State<OpenersScreen> {
  String? striker;
  String? nonStriker;
  String? bowler;
  final strikerManual = TextEditingController();
  final nonStrikerManual = TextEditingController();
  final bowlerManual = TextEditingController();

  @override
  void dispose() {
    strikerManual.dispose();
    nonStrikerManual.dispose();
    bowlerManual.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _options(List<String> players) => [
    ...players.map((p) => DropdownMenuItem(value: p, child: Text(p))),
    const DropdownMenuItem(
      value: '__manual__',
      child: Text('+ Add new player', style: TextStyle(color: AppColors.accent)),
    ),
  ];

  void _confirm() {
    final s = widget.state;
    final finalStriker = striker == '__manual__' ? strikerManual.text.trim() : striker;
    final finalNonStriker =
    nonStriker == '__manual__' ? nonStrikerManual.text.trim() : nonStriker;
    final finalBowler = bowler == '__manual__' ? bowlerManual.text.trim() : bowler;

    if (finalStriker == null || finalStriker.isEmpty) {
      _showError('Select or enter a striker.');
      return;
    }
    if (finalNonStriker == null || finalNonStriker.isEmpty) {
      _showError('Select or enter a non-striker.');
      return;
    }
    if (finalBowler == null || finalBowler.isEmpty) {
      _showError('Select or enter a bowler.');
      return;
    }
    if (finalStriker == finalNonStriker) {
      _showError('Striker and non-striker must be different players.');
      return;
    }

    s.striker = finalStriker;
    s.nonStriker = finalNonStriker;
    s.bowler = finalBowler;
    s.initPlayerStat(finalStriker);
    s.initPlayerStat(finalNonStriker);
    s.initBowlerStat(finalBowler);

    widget.onConfirm();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final battingTeam = s.teamObj(s.battingTeam!);
    final bowlingTeam = s.teamObj(s.bowlingTeam!);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        SectionCard(
          title: 'Select opening batsmen — ${battingTeam.name}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Striker', style: AppTextStyles.small),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                dropdownColor: AppColors.panel2,
                isExpanded: true,
                value: striker,
                hint: const Text('Select striker'),
                items: _options(battingTeam.players),
                onChanged: (v) => setState(() => striker = v),
              ),
              if (striker == '__manual__') ...[
                const SizedBox(height: 8),
                TextField(
                    controller: strikerManual,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(hintText: 'Striker name')),
              ],
              const SizedBox(height: 12),
              const Text('Non-striker', style: AppTextStyles.small),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                dropdownColor: AppColors.panel2,
                isExpanded: true,
                value: nonStriker,
                hint: const Text('Select non-striker'),
                items: _options(battingTeam.players),
                onChanged: (v) => setState(() => nonStriker = v),
              ),
              if (nonStriker == '__manual__') ...[
                const SizedBox(height: 8),
                TextField(
                    controller: nonStrikerManual,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(hintText: 'Non-striker name')),
              ],
            ],
          ),
        ),
        SectionCard(
          title: 'Select opening bowler — ${bowlingTeam.name}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: AppColors.panel2,
                isExpanded: true,
                value: bowler,
                hint: const Text('Select bowler'),
                items: _options(bowlingTeam.players),
                onChanged: (v) => setState(() => bowler = v),
              ),
              if (bowler == '__manual__') ...[
                const SizedBox(height: 8),
                TextField(
                    controller: bowlerManual,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(hintText: 'Bowler name')),
              ],
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: _confirm, child: const Text('Start innings ▶')),
        ),
      ],
    );
  }
}