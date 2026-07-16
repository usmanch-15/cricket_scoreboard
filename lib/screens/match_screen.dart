import 'package:flutter/material.dart';
import '../models/match_state.dart';
import '../theme/app_theme.dart';
import '../widgets/scoreboard_widgets.dart';
import '../dialogs/match_dialogs.dart';

class MatchScreen extends StatefulWidget {
  final MatchState state;
  final VoidCallback onChanged;
  final VoidCallback onInningsEnd; // 1st innings done -> go to openers again
  final VoidCallback onMatchEnd; // 2nd innings done -> go to result screen
  final VoidCallback onReset;

  const MatchScreen({
    super.key,
    required this.state,
    required this.onChanged,
    required this.onInningsEnd,
    required this.onMatchEnd,
    required this.onReset,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  String activeTab = 'summary';

  MatchState get s => widget.state;

  /// Call after any *legal* delivery (runs, leg bye, bye, wicket on a
  /// normal ball). Handles over-completion and innings-completion.
  void _afterLegalBall() {
    final inningsDone = s.checkInningsEnd();
    setState(() {});
    widget.onChanged();

    if (inningsDone) {
      _handleInningsEnd();
      return;
    }
    final overDone = s.checkOverComplete();
    if (overDone) {
      setState(() {});
      widget.onChanged();
      _promptNewBowler();
    }
  }

  /// Call after an *illegal* delivery (wide / no-ball). These never
  /// complete an over, but the chasing team can still cross the target
  /// off extras, so the innings-end check still matters.
  void _afterIllegalBall() {
    final inningsDone = s.checkInningsEnd();
    setState(() {});
    widget.onChanged();
    if (inningsDone) _handleInningsEnd();
  }

  void _handleInningsEnd() {
    if (s.innings == 1) {
      final firstScore = s.score;
      s.startSecondInnings();
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            'Innings 1 khatam! Score: $firstScore. Ab ${s.teamName(s.battingTeam!)} batting karegi.')),
      );
      widget.onInningsEnd();
    } else {
      s.finishMatch();
      widget.onChanged();
      widget.onMatchEnd();
    }
  }

  Future<void> _promptNewBowler() async {
    final bowlTeam = s.teamObj(s.bowlingTeam!);
    final options = bowlTeam.players
        .where((p) => p != s.bowler && p != s.previousOverBowler)
        .toList();
    final fallback = bowlTeam.players.where((p) => p != s.previousOverBowler).toList();
    final chosen = await showChangeBowlerDialog(
      context: context,
      options: options.isNotEmpty ? options : (fallback.isNotEmpty ? fallback : bowlTeam.players),
    );
    if (chosen != null && chosen.isNotEmpty) {
      setState(() {
        s.bowler = chosen;
        s.initBowlerStat(chosen);
      });
      widget.onChanged();
    }
  }

  Future<void> _openChangeBowler() => _promptNewBowler();

  Future<void> _openChangeBatsman() async {
    final battingTeam = s.teamObj(s.battingTeam!);
    final available = battingTeam.players
        .where((p) =>
    !(s.battingStats[p]?.out ?? false) && p != s.striker && p != s.nonStriker)
        .toList();
    final result = await showChangeBatsmanDialog(context: context, options: available);
    if (result != null && result.name.isNotEmpty) {
      setState(() {
        s.initPlayerStat(result.name);
        if (result.which == 'striker') {
          s.striker = result.name;
        } else {
          s.nonStriker = result.name;
        }
      });
      widget.onChanged();
    }
  }

  Future<void> _openWicket() async {
    final battingTeam = s.teamObj(s.battingTeam!);
    final available = battingTeam.players
        .where((p) =>
    !(s.battingStats[p]?.out ?? false) && p != s.striker && p != s.nonStriker)
        .toList();
    final result = await showWicketDialog(
      context: context,
      strikerName: s.striker ?? 'Striker',
      nonStrikerName: s.nonStriker ?? 'Non-striker',
      availableBatsmen: available,
    );
    if (result != null) {
      setState(() => s.recordWicket(
        dismissalType: result.dismissal,
        nextBatsman: result.nextBatsman,
        whichEnd: result.whichEnd,
        runsBeforeDismissal: result.runsBeforeDismissal,
      ));
      _afterLegalBall();
    }
  }

  Future<void> _addLegBye() async {
    final runs = await showRunCountDialog(context: context, title: 'Kitne leg byes?');
    if (runs != null) {
      setState(() => s.addLegBye(runs));
      _afterLegalBall();
    }
  }

  Future<void> _addBye() async {
    final runs = await showRunCountDialog(context: context, title: 'Kitne byes?');
    if (runs != null) {
      setState(() => s.addBye(runs));
      _afterLegalBall();
    }
  }

  void _addRuns(int runs) {
    setState(() => s.addRuns(runs));
    _afterLegalBall();
  }

  Future<void> _addWide() async {
    final extra = await showExtraRunsOnIllegalBallDialog(
      context: context,
      title: 'Wide + kitne extra runs bhaage?',
    );
    if (extra != null) {
      setState(() => s.addWide(extraRuns: extra));
      _afterIllegalBall();
    }
  }

  Future<void> _addNoBall() async {
    final batRuns = await showExtraRunsOnIllegalBallDialog(
      context: context,
      title: 'No ball par bat se kitne runs?',
    );
    if (batRuns != null) {
      setState(() => s.addNoBall(batRuns: batRuns));
      _afterIllegalBall();
    }
  }

  void _undo() {
    if (!s.canUndo) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nothing to undo.')));
      return;
    }
    setState(() => s.undo());
    widget.onChanged();
  }

  Future<void> _endInningsManually() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('End this innings now?', style: TextStyle(color: AppColors.text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('End')),
        ],
      ),
    );
    if (confirm == true) _handleInningsEnd();
  }

  @override
  Widget build(BuildContext context) {
    final crr = s.currentRunRate().toStringAsFixed(2);
    String crrText = 'CRR: $crr';
    if (s.innings == 2 && s.firstInningsScore != null) {
      final need = s.firstInningsScore! - s.score + 1;
      final ballsLeft = s.totalOvers * 6 - s.totalLegalBalls;
      crrText += ' | Need ${need > 0 ? need : 0} runs from $ballsLeft balls';
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        LedScoreHeader(
          teamLabel: '${s.teamName(s.battingTeam!)} — Innings ${s.innings}',
          scoreText: '${s.score}/${s.wickets}',
          oversText: 'Overs: ${s.currentOversStr()} / ${s.totalOvers}',
          crrText: crrText,
          thisOverBalls: s.ballHistoryThisOver,
        ),
        SectionCard(
          title: 'Batting',
          child: Column(
            children: [
              for (final name in [s.striker, s.nonStriker])
                if (name != null) _batsmanLine(name),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                    onPressed: _openChangeBatsman,
                    child: const Text('Change / retire batsman')),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Bowling',
          child: Column(
            children: [
              _bowlerLine(),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: _openChangeBowler, child: const Text('Change bowler')),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Add ball',
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.6,
                children: [
                  for (final r in [0, 1, 2, 3, 4, 5, 6, 7]) _runButton(r),
                ],
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.6,
                children: [
                  _extraButton('Wide', _addWide),
                  _extraButton('No ball', _addNoBall),
                  _extraButton('Leg bye', _addLegBye),
                  _extraButton('Bye', _addBye),
                  _extraButton('Dot ball', () => _addRuns(0)),
                  _extraButton('Change over', _openChangeBowler),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                  onPressed: _openWicket,
                  child: const Text('🎯 WICKET / OUT'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: _undo, child: const Text('↩ Undo last ball')),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(child: _tabButton('summary', 'Summary')),
            const SizedBox(width: 6),
            Expanded(child: _tabButton('scorecard', 'Scorecard')),
            const SizedBox(width: 6),
            Expanded(child: _tabButton('ballbyball', 'Ball by ball')),
          ],
        ),
        const SizedBox(height: 12),
        if (activeTab == 'summary')
          _summaryTab()
        else if (activeTab == 'scorecard')
          _scorecardTab()
        else
          _ballByBallTab(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                  onPressed: _endInningsManually, child: const Text('End innings')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                onPressed: widget.onReset,
                child: const Text('Reset match'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _batsmanLine(String name) {
    final st = s.battingStats[name];
    final isStriker = name == s.striker;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isStriker ? AppColors.accent : AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Text(name, style: AppTextStyles.body),
            if (isStriker) ...[
              const SizedBox(width: 6),
              const Text('striker', style: TextStyle(color: AppColors.amber, fontSize: 10)),
            ]
          ]),
          Text(
            '${st?.runs ?? 0} (${st?.balls ?? 0}) — 4s:${st?.fours ?? 0} 6s:${st?.sixes ?? 0}',
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }

  Widget _bowlerLine() {
    final bw = s.bowlingStats[s.bowler];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(s.bowler ?? '-', style: AppTextStyles.body),
          Text(
            '${bw?.oversDisplay ?? '0.0'} ov, ${bw?.runs ?? 0} runs, ${bw?.wickets ?? 0} wkts',
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }

  Widget _runButton(int r) {
    Color? borderColor;
    Color? textColor;
    if (r == 4) {
      borderColor = AppColors.blue;
      textColor = AppColors.blue;
    } else if (r == 6) {
      borderColor = AppColors.amber;
      textColor = AppColors.amber;
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: borderColor ?? AppColors.line),
        foregroundColor: textColor ?? AppColors.text,
        padding: EdgeInsets.zero,
      ),
      onPressed: () => _addRuns(r),
      child: Text('$r', style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _extraButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF5A4A1F)),
        foregroundColor: const Color(0xFFFFD166),
        padding: EdgeInsets.zero,
        textStyle: const TextStyle(fontSize: 12),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }

  Widget _tabButton(String tab, String label) {
    final active = activeTab == tab;
    return active
        ? ElevatedButton(
        onPressed: () => setState(() => activeTab = tab),
        style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 12)),
        child: Text(label))
        : OutlinedButton(
        onPressed: () => setState(() => activeTab = tab),
        style: OutlinedButton.styleFrom(textStyle: const TextStyle(fontSize: 12)),
        child: Text(label));
  }

  Widget _summaryTab() {
    return SectionCard(
      title: 'Extras this innings',
      child: Column(
        children: [
          StatRow(label: 'Wide', value: '${s.extras.wd}'),
          StatRow(label: 'No ball', value: '${s.extras.nb}'),
          StatRow(label: 'Leg bye', value: '${s.extras.lb}'),
          StatRow(label: 'Bye', value: '${s.extras.b}'),
          StatRow(label: 'Total extras', value: '${s.extras.total}'),
        ],
      ),
    );
  }

  Widget _scorecardTab() {
    return SectionCard(
      title: 'Batting card — ${s.teamName(s.battingTeam!)}',
      child: Column(
        children: [
          for (final entry in s.battingStats.entries)
            StatRow(
              label: entry.value.out ? '${entry.key} (${entry.value.howOut})' : '${entry.key} *',
              value: '${entry.value.runs} (${entry.value.balls})',
            ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('BOWLING CARD', style: AppTextStyles.cardTitle),
          ),
          const SizedBox(height: 8),
          for (final entry in s.bowlingStats.entries)
            StatRow(
              label: entry.key,
              value: '${entry.value.oversDisplay}-${entry.value.runs}-${entry.value.wickets}',
            ),
        ],
      ),
    );
  }

  Widget _ballByBallTab() {
    return SectionCard(
      title: 'Ball by ball — first ball to last',
      child: s.ballLog.isEmpty
          ? const Text('No balls bowled yet.', style: AppTextStyles.small)
          : ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 340),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: s.ballLog.length,
          itemBuilder: (ctx, i) {
            final e = s.ballLog[i];
            final isWicket = e.description.startsWith('OUT');
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line, width: 0.5)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(e.overBall, style: AppTextStyles.small),
                  ),
                  Expanded(
                    child: Text(
                      '${e.striker} b ${e.bowler} — ${e.description}',
                      style: TextStyle(
                        color: isWicket ? AppColors.red : AppColors.text,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(e.scoreAfter, style: AppTextStyles.small),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}