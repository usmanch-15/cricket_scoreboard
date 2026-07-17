import 'package:flutter/material.dart';
import '../models/match_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/scoreboard_widgets.dart';
import 'result_screen.dart';

/// Read-only detail view for a match pulled from history. Finished
/// matches reuse the same summary shown right after a live match ends
/// (result, Man of the Match, best performances, full scorecards, and
/// the ball-by-ball replay). Matches that were left mid-way show a
/// simpler live-snapshot view instead.
class HistoryDetailScreen extends StatelessWidget {
  final MatchState state;

  const HistoryDetailScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final title = '${state.teamA.name} vs ${state.teamB.name}';

    if (state.battingTeam == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(backgroundColor: AppColors.panel, title: Text(title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'This match never got past team setup, so there is nothing to show yet.',
              style: AppTextStyles.small,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (state.matchOver) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(backgroundColor: AppColors.panel, title: Text(title)),
        body: SafeArea(
          child: ResultScreen(
            state: state,
            onNewMatch: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.panel, title: Text(title)),
      body: SafeArea(child: _LiveSnapshotView(state: state)),
    );
  }
}

/// Read-only "where it was left off" view for a match that was never
/// finished (app closed mid-innings, or the user started a new match
/// without finishing the old one).
class _LiveSnapshotView extends StatefulWidget {
  final MatchState state;

  const _LiveSnapshotView({required this.state});

  @override
  State<_LiveSnapshotView> createState() => _LiveSnapshotViewState();
}

class _LiveSnapshotViewState extends State<_LiveSnapshotView> {
  bool showBallLog = false;

  MatchState get s => widget.state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.amber),
          ),
          child: Row(
            children: [
              const Icon(Icons.pending_outlined, color: AppColors.amber, size: 20),
              const SizedBox(width: 8),
              const Text('Match left in progress',
                  style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        for (int i = 0; i < s.completedInnings.length; i++) _completedInningsCard(s.completedInnings[i]),

        SectionCard(
          title: '${s.teamName(s.battingTeam!)} — Innings ${s.innings} (in progress)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.score}/${s.wickets}  (${s.currentOversStr()} / ${s.totalOvers} ov)',
                  style: const TextStyle(color: AppColors.accentGlow, fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('BATTING', style: AppTextStyles.cardTitle),
              ),
              const SizedBox(height: 6),
              for (final entry in s.battingStats.entries)
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
              for (final entry in s.bowlingStats.entries)
                StatRow(
                  label: entry.key,
                  value: '${entry.value.oversDisplay}-${entry.value.runs}-${entry.value.wickets}',
                ),
              const SizedBox(height: 6),
              StatRow(label: 'Extras', value: '${s.extras.total}'),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => showBallLog = !showBallLog),
                  child: Text(showBallLog ? 'Hide ball by ball' : 'Show ball by ball (first to last)'),
                ),
              ),
              if (showBallLog) ...[
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: s.ballLog.length,
                    itemBuilder: (ctx, i) => _ballLogRow(s.ballLog[i]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _completedInningsCard(InningsRecord inn) {
    return SectionCard(
      title: '${s.teamName(inn.battingTeam)} innings (completed) — ${inn.score}/${inn.wickets} (${inn.oversStr} ov)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in inn.battingStats.entries)
            StatRow(
              label: entry.value.out ? '${entry.key} (${entry.value.howOut})' : '${entry.key} *',
              value: '${entry.value.runs} (${entry.value.balls})',
            ),
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