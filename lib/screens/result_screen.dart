import 'package:flutter/material.dart';
import '../models/match_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/scoreboard_widgets.dart';

/// Full post-match summary, styled like a broadcast/ICC scorecard: a
/// clear result banner, a Player of the Match hero card, then a proper
/// batting + bowling scorecard for each innings (same columns a real
/// scorecard uses: R/B/4s/6s/SR for batters, O/R/W/Econ for bowlers) so
/// anyone glancing at it — not just the person who was scoring — can
/// immediately understand how the match went.
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

  bool get _hasBothScores => s.firstInningsBattingTeam != null && s.firstInningsScore != null;

  String _resultText() {
    if (!_hasBothScores) return 'Match ended.';
    final team1 = s.teamName(s.firstInningsBattingTeam!);
    final team2 = s.teamName(s.battingTeam!);
    final s1 = s.firstInningsScore!;
    final s2 = s.score;

    if (s2 > s1) {
      final wicketsLeft = s.totalWickets - s.wickets;
      return '${s.teamName(s.battingTeam!)} won by $wicketsLeft wicket${wicketsLeft == 1 ? '' : 's'}';
    } else if (s1 > s2) {
      return '$team1 won by ${s1 - s2} run${(s1 - s2) == 1 ? '' : 's'}';
    }
    return 'Match tied';
  }

  double _strikeRate(int runs, int balls) => balls > 0 ? (runs / balls) * 100 : 0;
  double _economy(int runs, int legalBalls) => legalBalls > 0 ? runs / (legalBalls / 6) : 0;

  @override
  Widget build(BuildContext context) {
    final mom = s.manOfTheMatch();
    final bestBat = s.bestBattingPerformance();
    final bestBowl = s.bestBowlingPerformance();
    final innings = s.analysisInnings;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _resultBanner(innings),
        const SizedBox(height: 14),

        if (mom != null) _playerOfTheMatchCard(mom),

        if (bestBat != null || bestBowl != null) ...[
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
                    sub: '${bestBowl.oversBowled} overs · Econ ${bestBowl.economy.toStringAsFixed(1)}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],

        for (int i = 0; i < innings.length; i++) _inningsScorecard(i, innings),

        if (innings.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No ball-by-ball data was saved for this match, so a full '
                  'scorecard isn\'t available.',
              style: AppTextStyles.small,
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: widget.onNewMatch, child: const Text('New match')),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ---------- result banner ----------

  Widget _resultBanner(List<InningsRecord> innings) {
    final team1Name = innings.isNotEmpty ? s.teamName(innings.first.battingTeam) : s.teamA.name;
    final team2Name = innings.length > 1 ? s.teamName(innings[1].battingTeam) : s.teamB.name;
    final score1 = innings.isNotEmpty ? '${innings.first.score}/${innings.first.wickets}' : '-';
    final score2 = innings.length > 1 ? '${innings[1].score}/${innings[1].wickets}' : '-';
    final overs1 = innings.isNotEmpty ? innings.first.oversStr : '';
    final overs2 = innings.length > 1 ? innings[1].oversStr : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF16261C), Color(0xFF101C15)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Text('MATCH RESULT',
              style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 1.4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _teamScoreColumn(team1Name, score1, overs1)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('vs', style: AppTextStyles.small),
              ),
              Expanded(child: _teamScoreColumn(team2Name, score2, overs2)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _resultText(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.amber, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _teamScoreColumn(String name, String score, String overs) {
    return Column(
      children: [
        Text(name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(score,
            style: const TextStyle(
                color: AppColors.accentGlow, fontSize: 24, fontWeight: FontWeight.w700)),
        if (overs.isNotEmpty)
          Text('($overs ov)', style: AppTextStyles.small),
      ],
    );
  }

  // ---------- player of the match ----------

  Widget _playerOfTheMatchCard(PlayerPerformance mom) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber, width: 1.2),
        boxShadow: [
          BoxShadow(color: AppColors.amber.withOpacity(0.18), blurRadius: 18, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.panel2,
              border: Border.all(color: AppColors.amber),
            ),
            child: const Text('🏅', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PLAYER OF THE MATCH',
                    style: TextStyle(color: AppColors.amber, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(mom.name,
                    style: const TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  [
                    if (mom.ballsFaced > 0) '${mom.runs} runs (${mom.ballsFaced} balls)',
                    if (mom.ballsBowled > 0) '${mom.wickets}/${mom.runsConceded} (${mom.oversBowled} ov)',
                  ].join('  •  '),
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
        ],
      ),
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
          Text(name, style: AppTextStyles.body, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.accentGlow, fontSize: 18, fontWeight: FontWeight.w600)),
          Text(sub, style: AppTextStyles.small),
        ],
      ),
    );
  }

  // ---------- full scorecard per innings ----------

  Widget _inningsScorecard(int index, List<InningsRecord> innings) {
    final inn = innings[index];
    final expanded = expandedInnings == index;
    final extras = inn.extras;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${s.teamName(inn.battingTeam)} innings',
                  style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Text('${inn.score}/${inn.wickets}  (${inn.oversStr} ov)',
                  style: const TextStyle(color: AppColors.accentGlow, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),

          // ---- batting table ----
          _tableHeader(const ['BATTER', 'R', 'B', '4s', '6s', 'SR']),
          const Divider(color: AppColors.line, height: 14),
          for (final entry in inn.battingStats.entries)
            _battingRow(entry.key, entry.value),

          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Extras: ${extras.total}  '
                  '(b ${extras.b}, lb ${extras.lb}, w ${extras.wd}, nb ${extras.nb})',
              style: AppTextStyles.small,
            ),
          ),

          const SizedBox(height: 14),
          // ---- bowling table ----
          _tableHeader(const ['BOWLER', 'O', 'R', 'W', 'ECON']),
          const Divider(color: AppColors.line, height: 14),
          for (final entry in inn.bowlingStats.entries)
            _bowlingRow(entry.key, entry.value),

          const SizedBox(height: 12),
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

  Widget _tableHeader(List<String> labels) {
    return Row(
      children: [
        Expanded(flex: 3, child: Text(labels[0], style: AppTextStyles.cardTitle)),
        for (final l in labels.skip(1))
          Expanded(
            flex: 1,
            child: Text(l, textAlign: TextAlign.right, style: AppTextStyles.cardTitle),
          ),
      ],
    );
  }

  Widget _battingRow(String name, BattingStat bs) {
    final sr = _strikeRate(bs.runs, bs.balls);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.body, overflow: TextOverflow.ellipsis),
                Text(
                  bs.out ? bs.howOut : 'not out',
                  style: TextStyle(
                    color: bs.out ? AppColors.muted : AppColors.accent,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text('${bs.runs}', textAlign: TextAlign.right, style: AppTextStyles.body)),
          Expanded(flex: 1, child: Text('${bs.balls}', textAlign: TextAlign.right, style: AppTextStyles.small)),
          Expanded(flex: 1, child: Text('${bs.fours}', textAlign: TextAlign.right, style: AppTextStyles.small)),
          Expanded(flex: 1, child: Text('${bs.sixes}', textAlign: TextAlign.right, style: AppTextStyles.small)),
          Expanded(flex: 1, child: Text(sr.toStringAsFixed(0), textAlign: TextAlign.right, style: AppTextStyles.small)),
        ],
      ),
    );
  }

  Widget _bowlingRow(String name, BowlingStat bw) {
    final econ = _economy(bw.runs, bw.legalBalls);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: AppTextStyles.body, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 1, child: Text(bw.oversDisplay, textAlign: TextAlign.right, style: AppTextStyles.small)),
          Expanded(flex: 1, child: Text('${bw.runs}', textAlign: TextAlign.right, style: AppTextStyles.small)),
          Expanded(
            flex: 1,
            child: Text('${bw.wickets}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: bw.wickets > 0 ? AppColors.accentGlow : AppColors.text,
                  fontWeight: bw.wickets > 0 ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 15,
                )),
          ),
          Expanded(flex: 1, child: Text(econ.toStringAsFixed(1), textAlign: TextAlign.right, style: AppTextStyles.small)),
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