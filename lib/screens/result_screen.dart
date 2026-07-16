import 'package:flutter/material.dart';
import '../models/match_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/scoreboard_widgets.dart';

class ResultScreen extends StatefulWidget {
  final MatchState state;
  final VoidCallback onNewMatch;

  const ResultScreen({super.key, required this.state, required this.onNewMatch});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int expandedInnings = -1; // which innings' ball-by-ball log is expanded

  MatchState get s => widget.state;

  String _resultText() {
    final team1 = s.teamName(s.firstInningsBattingTeam!);
    final team2 = s.teamName(s.battingTeam!);
    final s1 = s.firstInningsScore!;
    final s2 = s.score;

    if (s2 > s1) {
      final wicketsLeft = s.totalWickets - s.wickets;
      return '$team2 won by $wicketsLeft wicket(s)! ($s2/${s.wickets} vs $s1)';
    } else if (s1 > s2) {
      return '$team1 won by ${s1 - s2} run(s)! ($s1 vs $s2/${s.wickets})';
    }
    return 'Match tied! Both teams scored $s1.';
  }

  @override
  Widget build(BuildContext context) {
    final mom = s.manOfTheMatch();
    final bestBat = s.bestBattingPerformance();
    final bestBowl = s.bestBowlingPerformance();
    final topScorers = s.topScorers(limit: 3);
    final topWickets = s.topWicketTakers(limit: 3);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const SizedBox(height: 8),
        SectionCard(
          title: '🏆 Match result',
          child: Column(
            children: [
              Text(
                _resultText(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.amber, fontSize: 17),
              ),
            ],
          ),
        ),

        if (mom != null)
          SectionCard(
            title: '⭐ Man of the match',
            child: _performanceHighlight(
              name: mom.name,
              lines: [
                if (mom.ballsFaced > 0)
                  '${mom.runs} runs off ${mom.ballsFaced} balls (${mom.fours}x4, ${mom.sixes}x6)',
                if (mom.ballsBowled > 0)
                  '${mom.wickets} wkts, ${mom.oversBowled} overs, ${mom.runsConceded} runs',
              ],
            ),
          ),

        Row(
          children: [
            if (bestBat != null)
              Expanded(
                child: _miniCard(
                  title: 'Best batting',
                  name: bestBat.name,
                  value: '${bestBat.runs} (${bestBat.ballsFaced})',
                  sub: 'SR ${bestBat.strikeRate.toStringAsFixed(1)}',
                ),
              ),
            if (bestBat != null && bestBowl != null) const SizedBox(width: 10),
            if (bestBowl != null)
              Expanded(
                child: _miniCard(
                  title: 'Best bowling',
                  name: bestBowl.name,
                  value: '${bestBowl.wickets}/${bestBowl.runsConceded}',
                  sub: '${bestBowl.oversBowled} overs',
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (topScorers.isNotEmpty)
          SectionCard(
            title: 'Top scorers',
            child: Column(
              children: [
                for (final p in topScorers)
                  StatRow(label: p.name, value: '${p.runs} (${p.ballsFaced})'),
              ],
            ),
          ),

        if (topWickets.isNotEmpty)
          SectionCard(
            title: 'Top wicket takers',
            child: Column(
              children: [
                for (final p in topWickets)
                  StatRow(
                      label: p.name, value: '${p.wickets}/${p.runsConceded} (${p.oversBowled})'),
              ],
            ),
          ),

        for (int i = 0; i < s.completedInnings.length; i++) _inningsCard(i),

        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: widget.onNewMatch, child: const Text('New match')),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _performanceHighlight({required String name, required List<String> lines}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(color: AppColors.amber, fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        for (final l in lines) Text(l, style: AppTextStyles.body),
      ],
    );
  }

  Widget _miniCard({required String title, required String name, required String value, required String sub}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          Text(name, style: AppTextStyles.body),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.accentGlow, fontSize: 18, fontWeight: FontWeight.w600)),
          Text(sub, style: AppTextStyles.small),
        ],
      ),
    );
  }

  Widget _inningsCard(int index) {
    final inn = s.completedInnings[index];
    final expanded = expandedInnings == index;
    return SectionCard(
      title: '${s.teamName(inn.battingTeam)} innings — ${inn.score}/${inn.wickets} (${inn.oversStr} ov)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in inn.battingStats.entries)
            StatRow(
              label: entry.value.out ? '${entry.key} (${entry.value.howOut})' : '${entry.key} *',
              value: '${entry.value.runs} (${entry.value.balls})',
            ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('BOWLING', style: AppTextStyles.cardTitle),
          ),
          const SizedBox(height: 6),
          for (final entry in inn.bowlingStats.entries)
            StatRow(
              label: entry.key,
              value: '${entry.value.oversDisplay}-${entry.value.runs}-${entry.value.wickets}',
            ),
          const SizedBox(height: 6),
          StatRow(label: 'Extras', value: '${inn.extras.total}'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => expandedInnings = expanded ? -1 : index),
              child: Text(expanded ? 'Hide ball by ball' : 'Show ball by ball (first to last)'),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: inn.ballLog.length,
                itemBuilder: (ctx, i) => _ballLogRow(inn.ballLog[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ballLogRow(BallLogEntry e) {
    final isWicket = e.description.startsWith('OUT');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(e.overBall, style: AppTextStyles.small)),
          Expanded(
            child: Text(
              '${e.striker} b ${e.bowler} — ${e.description}',
              style: TextStyle(color: isWicket ? AppColors.red : AppColors.text, fontSize: 13),
            ),
          ),
          Text(e.scoreAfter, style: AppTextStyles.small),
        ],
      ),
    );
  }
}