import 'models.dart';

/// Holds the entire live state of a match and all the scoring logic.
/// This is the single source of truth; screens just read/mutate it
/// through the methods below and re-render.
class MatchState {
  Team teamA = Team(name: 'Team A');
  Team teamB = Team(name: 'Team B');

  int totalOvers = 20;
  int totalWickets = 10;

  String? tossWinner; // 'A' or 'B'
  String? tossDecision; // 'bat' or 'bowl'

  String currentPlayerTeam = 'A'; // used only during the setup screen

  String? battingTeam; // 'A' or 'B'
  String? bowlingTeam;

  int innings = 1;
  bool matchOver = false;

  int? firstInningsScore;
  String? firstInningsBattingTeam;

  int score = 0;
  int wickets = 0;
  int legalBalls = 0; // balls bowled in the current over
  int totalLegalBalls = 0; // balls bowled in the whole innings

  List<BallEvent> ballHistoryThisOver = [];

  /// Full ball-by-ball commentary for the *current* innings, first ball
  /// to last. Completed innings are frozen into [completedInnings].
  List<BallLogEntry> ballLog = [];

  /// Snapshots of every innings once it finishes — used for the match
  /// summary, man-of-the-match, best performance, and full replay.
  List<InningsRecord> completedInnings = [];

  String? striker;
  String? nonStriker;
  String? bowler;
  String? previousOverBowler; // enforces "can't bowl consecutive overs"

  Map<String, BattingStat> battingStats = {};
  Map<String, BowlingStat> bowlingStats = {};
  Extras extras = Extras();

  // Undo stack: snapshots of the mutable fields, most recent last.
  final List<Map<String, dynamic>> _undoStack = [];

  Team teamObj(String letter) => letter == 'A' ? teamA : teamB;
  String teamName(String letter) => teamObj(letter).name;

  void initPlayerStat(String name) {
    battingStats.putIfAbsent(name, () => BattingStat());
  }

  void initBowlerStat(String name) {
    bowlingStats.putIfAbsent(name, () => BowlingStat());
  }

  String currentOversStr() => '${totalLegalBalls ~/ 6}.${totalLegalBalls % 6}';

  double currentRunRate() =>
      totalLegalBalls > 0 ? score / (totalLegalBalls / 6) : 0.0;

  void _rotateStrike() {
    final t = striker;
    striker = nonStriker;
    nonStriker = t;
  }

  void _logBall(String description) {
    ballLog.add(BallLogEntry(
      overBall: currentOversStr(),
      striker: striker ?? '-',
      bowler: bowler ?? '-',
      description: description,
      scoreAfter: '$score/$wickets',
    ));
  }

  // ---------- undo ----------
  void _pushUndoSnapshot() {
    _undoStack.add({
      'score': score,
      'wickets': wickets,
      'legalBalls': legalBalls,
      'totalLegalBalls': totalLegalBalls,
      'ballHistoryThisOver': ballHistoryThisOver.map((b) => b.toJson()).toList(),
      'ballLog': ballLog.map((b) => b.toJson()).toList(),
      'striker': striker,
      'nonStriker': nonStriker,
      'bowler': bowler,
      'battingStats': battingStats.map((k, v) => MapEntry(k, v.toJson())),
      'bowlingStats': bowlingStats.map((k, v) => MapEntry(k, v.toJson())),
      'extras': extras.toJson(),
    });
    if (_undoStack.length > 80) _undoStack.removeAt(0);
  }

  bool get canUndo => _undoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isEmpty) return;
    final prev = _undoStack.removeLast();
    score = prev['score'] as int;
    wickets = prev['wickets'] as int;
    legalBalls = prev['legalBalls'] as int;
    totalLegalBalls = prev['totalLegalBalls'] as int;
    ballHistoryThisOver = (prev['ballHistoryThisOver'] as List)
        .map((b) => BallEvent.fromJson(b as Map<String, dynamic>))
        .toList();
    ballLog = (prev['ballLog'] as List)
        .map((b) => BallLogEntry.fromJson(b as Map<String, dynamic>))
        .toList();
    striker = prev['striker'] as String?;
    nonStriker = prev['nonStriker'] as String?;
    bowler = prev['bowler'] as String?;
    battingStats = (prev['battingStats'] as Map).map((k, v) =>
        MapEntry(k as String, BattingStat.fromJson(v as Map<String, dynamic>)));
    bowlingStats = (prev['bowlingStats'] as Map).map((k, v) =>
        MapEntry(k as String, BowlingStat.fromJson(v as Map<String, dynamic>)));
    extras = Extras.fromJson(prev['extras'] as Map<String, dynamic>);
  }

  // ---------- scoring ----------

  /// Add `runs` scored off the bat on a completely normal, legal delivery.
  /// Implements the ICC strike-rotation rule: strike changes on odd runs
  /// (1, 3, 5, 7...) but never just because a wicket fell (e.g. a catch),
  /// and never for even runs / boundaries.
  void addRuns(int runs) {
    _pushUndoSnapshot();
    score += runs;

    final bs = battingStats[striker!]!;
    bs.runs += runs;
    bs.balls += 1;
    if (runs == 4) bs.fours++;
    if (runs == 6) bs.sixes++;

    final bw = bowlingStats[bowler!]!;
    bw.legalBalls += 1;
    bw.runs += runs;

    legalBalls++;
    totalLegalBalls++;

    String kind = '';
    if (runs == 4) kind = 'four';
    if (runs == 6) kind = 'six';
    ballHistoryThisOver.add(BallEvent(runs == 0 ? '0' : '$runs', kind));
    _logBall(runs == 0 ? 'Dot ball' : '$runs run${runs == 1 ? '' : 's'}');

    if (runs % 2 == 1) _rotateStrike();
  }

  void addDot() => addRuns(0);

  /// Wide ball. `extraRuns` are runs run by the batsmen while the ball
  /// was wide (byes on a wide) — always in addition to the mandatory
  /// 1-run wide penalty. Does not count as a legal delivery.
  void addWide({int extraRuns = 0}) {
    _pushUndoSnapshot();
    final total = 1 + extraRuns;
    score += total;
    extras.wd += total;
    bowlingStats[bowler!]!.runs += total;
    ballHistoryThisOver
        .add(BallEvent(extraRuns == 0 ? 'Wd' : 'Wd+$extraRuns', 'wd'));
    _logBall(extraRuns == 0 ? 'Wide' : 'Wide + $extraRuns run${extraRuns == 1 ? '' : 's'}');
    // Batsmen can still run between wickets on a wide, so an odd number
    // of run-throughs rotates the strike; the ball itself doesn't count.
    if (extraRuns % 2 == 1) _rotateStrike();
  }

  /// No ball. `batRuns` are runs scored off the bat on the no ball
  /// (the batsman can still hit it for four/six). Does not count as a
  /// legal delivery.
  void addNoBall({int batRuns = 0}) {
    _pushUndoSnapshot();
    final total = 1 + batRuns;
    score += total;
    extras.nb += 1;
    if (batRuns > 0) {
      final bs = battingStats[striker!]!;
      bs.runs += batRuns;
      if (batRuns == 4) bs.fours++;
      if (batRuns == 6) bs.sixes++;
    }
    bowlingStats[bowler!]!.runs += total;
    ballHistoryThisOver
        .add(BallEvent(batRuns == 0 ? 'Nb' : 'Nb+$batRuns', 'nb'));
    _logBall(batRuns == 0 ? 'No ball' : 'No ball + $batRuns run${batRuns == 1 ? '' : 's'}');
    if (batRuns % 2 == 1) _rotateStrike();
  }

  void addLegBye(int runs) {
    _pushUndoSnapshot();
    score += runs;
    extras.lb += runs;
    battingStats[striker!]!.balls += 1;
    bowlingStats[bowler!]!.legalBalls += 1;
    legalBalls++;
    totalLegalBalls++;
    ballHistoryThisOver.add(BallEvent('Lb$runs', ''));
    _logBall('$runs leg bye${runs == 1 ? '' : 's'}');
    if (runs % 2 == 1) _rotateStrike();
  }

  void addBye(int runs) {
    _pushUndoSnapshot();
    score += runs;
    extras.b += runs;
    battingStats[striker!]!.balls += 1;
    bowlingStats[bowler!]!.legalBalls += 1;
    legalBalls++;
    totalLegalBalls++;
    ballHistoryThisOver.add(BallEvent('B$runs', ''));
    _logBall('$runs bye${runs == 1 ? '' : 's'}');
    if (runs % 2 == 1) _rotateStrike();
  }

  /// Records a wicket. `whichEnd` is 'striker' or 'nonstriker' — run outs
  /// can dismiss either batsman, everything else is always the striker.
  /// Per ICC rules, a dismissal never rotates the strike by itself; only
  /// the run-based rotation logic above ever swaps ends.
  void recordWicket({
    required String dismissalType,
    required String nextBatsman,
    String whichEnd = 'striker',
    int runsBeforeDismissal = 0,
  }) {
    _pushUndoSnapshot();
    final outName = whichEnd == 'nonstriker' ? nonStriker! : striker!;
    final bs = battingStats[outName]!;
    bs.out = true;
    bs.howOut = dismissalType == 'Run Out' ? 'Run out' : '$dismissalType b $bowler';

    // Runs completed before the run out still count.
    if (runsBeforeDismissal > 0) {
      score += runsBeforeDismissal;
      bs.runs += runsBeforeDismissal;
      bowlingStats[bowler!]!.runs += runsBeforeDismissal;
    }

    bs.balls += 1;
    bowlingStats[bowler!]!.legalBalls += 1;
    if (dismissalType != 'Run Out') {
      bowlingStats[bowler!]!.wickets += 1;
    }

    wickets++;
    legalBalls++;
    totalLegalBalls++;
    ballHistoryThisOver.add(BallEvent('W', 'w'));
    _logBall('OUT - $dismissalType ($outName)');

    if (whichEnd == 'nonstriker') {
      nonStriker = nextBatsman;
    } else {
      striker = nextBatsman;
    }
    initPlayerStat(nextBatsman);
  }

  /// Returns true if the over just completed (6 legal balls bowled).
  /// Also rotates strike (batsmen change ends between overs) and
  /// resets the over-ball display.
  bool checkOverComplete() {
    if (legalBalls >= 6) {
      legalBalls = 0;
      ballHistoryThisOver = [];
      previousOverBowler = bowler;
      _rotateStrike();
      return true;
    }
    return false;
  }

  /// Returns true if the innings should end now (all out, overs used up,
  /// or - while chasing - the target has already been passed, which can
  /// happen even on a wide/no-ball).
  bool checkInningsEnd() {
    if (wickets >= totalWickets || totalLegalBalls >= totalOvers * 6) {
      return true;
    }
    if (innings == 2 && firstInningsScore != null && score > firstInningsScore!) {
      return true;
    }
    return false;
  }

  InningsRecord _snapshotCurrentInnings() {
    return InningsRecord(
      battingTeam: battingTeam!,
      bowlingTeam: bowlingTeam!,
      score: score,
      wickets: wickets,
      oversStr: currentOversStr(),
      battingStats: battingStats.map((k, v) => MapEntry(k, v)),
      bowlingStats: bowlingStats.map((k, v) => MapEntry(k, v)),
      extras: extras,
      ballLog: List.of(ballLog),
    );
  }

  /// Moves from innings 1 to innings 2, swapping batting/bowling teams,
  /// freezing innings 1 into [completedInnings], and resetting all
  /// per-innings counters.
  void startSecondInnings() {
    completedInnings.add(_snapshotCurrentInnings());
    firstInningsScore = score;
    firstInningsBattingTeam = battingTeam;

    final newBat = bowlingTeam;
    final newBowl = battingTeam;
    battingTeam = newBat;
    bowlingTeam = newBowl;
    innings = 2;

    score = 0;
    wickets = 0;
    legalBalls = 0;
    totalLegalBalls = 0;
    ballHistoryThisOver = [];
    ballLog = [];
    striker = null;
    nonStriker = null;
    bowler = null;
    previousOverBowler = null;
    battingStats = {};
    bowlingStats = {};
    extras = Extras();
    _undoStack.clear();
  }

  /// Freezes the second (final) innings into [completedInnings] once the
  /// match is over. Call once, right when the match ends.
  void finishMatch() {
    completedInnings.add(_snapshotCurrentInnings());
    matchOver = true;
  }

  /// Innings records to use for post-match analysis (Man of the Match,
  /// best batting/bowling, top lists). Normally this is just
  /// [completedInnings]. But a match saved by an older build of the app
  /// (before this feature existed) — or any match where the final
  /// innings snapshot never made it in for some reason — would otherwise
  /// show an empty summary even though the raw ball-by-ball data is
  /// right there in [battingStats]/[bowlingStats]. So: if the match is
  /// marked finished but we're missing the expected two innings, and the
  /// live stats still have data sitting in them, fold that in as a
  /// best-effort final innings rather than showing nothing.
  List<InningsRecord> get analysisInnings {
    final expectedCount = firstInningsBattingTeam != null ? 2 : 1;
    final hasLiveData = battingStats.isNotEmpty || bowlingStats.isNotEmpty;
    if (matchOver && completedInnings.length < expectedCount && hasLiveData) {
      return [...completedInnings, _snapshotCurrentInnings()];
    }
    return completedInnings;
  }

  /// Combines batting + bowling figures for every player across every
  /// completed innings, keyed by player name.
  Map<String, PlayerPerformance> combinedPerformances() {
    final map = <String, PlayerPerformance>{};
    PlayerPerformance perf(String name) =>
        map.putIfAbsent(name, () => PlayerPerformance(name));

    for (final inn in analysisInnings) {
      inn.battingStats.forEach((name, bs) {
        final p = perf(name);
        p.runs += bs.runs;
        p.ballsFaced += bs.balls;
        p.fours += bs.fours;
        p.sixes += bs.sixes;
        p.inningsBatted += 1;
      });
      inn.bowlingStats.forEach((name, bw) {
        final p = perf(name);
        p.wickets += bw.wickets;
        p.runsConceded += bw.runs;
        p.ballsBowled += bw.legalBalls;
      });
    }
    return map;
  }

  /// Highest combined-impact player across the whole match. Null if no
  /// innings has been completed yet.
  PlayerPerformance? manOfTheMatch() {
    final perfs = combinedPerformances().values.toList();
    if (perfs.isEmpty) return null;
    perfs.sort((a, b) => b.impactPoints.compareTo(a.impactPoints));
    return perfs.first;
  }

  /// The single highest individual batting innings across the match.
  PlayerPerformance? bestBattingPerformance() {
    final perfs = combinedPerformances().values.where((p) => p.ballsFaced > 0).toList();
    if (perfs.isEmpty) return null;
    perfs.sort((a, b) => b.runs.compareTo(a.runs));
    return perfs.first;
  }

  /// Best bowling figures: most wickets, tie-broken by fewest runs conceded.
  PlayerPerformance? bestBowlingPerformance() {
    final perfs = combinedPerformances().values.where((p) => p.ballsBowled > 0).toList();
    if (perfs.isEmpty) return null;
    perfs.sort((a, b) {
      final w = b.wickets.compareTo(a.wickets);
      if (w != 0) return w;
      return a.runsConceded.compareTo(b.runsConceded);
    });
    return perfs.first;
  }

  /// Top run scorers, highest first.
  List<PlayerPerformance> topScorers({int limit = 5}) {
    final perfs = combinedPerformances().values.where((p) => p.ballsFaced > 0).toList();
    perfs.sort((a, b) => b.runs.compareTo(a.runs));
    return perfs.take(limit).toList();
  }

  /// Top wicket takers, most wickets first, tie-broken by economy.
  List<PlayerPerformance> topWicketTakers({int limit = 5}) {
    final perfs = combinedPerformances().values.where((p) => p.ballsBowled > 0).toList();
    perfs.sort((a, b) {
      final w = b.wickets.compareTo(a.wickets);
      if (w != 0) return w;
      return a.economy.compareTo(b.economy);
    });
    return perfs.take(limit).toList();
  }

  // ---------- persistence ----------
  Map<String, dynamic> toJson() => {
    'teamA': teamA.toJson(),
    'teamB': teamB.toJson(),
    'totalOvers': totalOvers,
    'totalWickets': totalWickets,
    'tossWinner': tossWinner,
    'tossDecision': tossDecision,
    'currentPlayerTeam': currentPlayerTeam,
    'battingTeam': battingTeam,
    'bowlingTeam': bowlingTeam,
    'innings': innings,
    'matchOver': matchOver,
    'firstInningsScore': firstInningsScore,
    'firstInningsBattingTeam': firstInningsBattingTeam,
    'score': score,
    'wickets': wickets,
    'legalBalls': legalBalls,
    'totalLegalBalls': totalLegalBalls,
    'ballHistoryThisOver': ballHistoryThisOver.map((b) => b.toJson()).toList(),
    'ballLog': ballLog.map((b) => b.toJson()).toList(),
    'completedInnings': completedInnings.map((i) => i.toJson()).toList(),
    'striker': striker,
    'nonStriker': nonStriker,
    'bowler': bowler,
    'previousOverBowler': previousOverBowler,
    'battingStats': battingStats.map((k, v) => MapEntry(k, v.toJson())),
    'bowlingStats': bowlingStats.map((k, v) => MapEntry(k, v.toJson())),
    'extras': extras.toJson(),
  };

  static MatchState fromJson(Map<String, dynamic> json) {
    final m = MatchState();
    m.teamA = Team.fromJson(json['teamA'] as Map<String, dynamic>);
    m.teamB = Team.fromJson(json['teamB'] as Map<String, dynamic>);
    m.totalOvers = json['totalOvers'] as int;
    m.totalWickets = json['totalWickets'] as int;
    m.tossWinner = json['tossWinner'] as String?;
    m.tossDecision = json['tossDecision'] as String?;
    m.currentPlayerTeam = json['currentPlayerTeam'] as String;
    m.battingTeam = json['battingTeam'] as String?;
    m.bowlingTeam = json['bowlingTeam'] as String?;
    m.innings = json['innings'] as int;
    m.matchOver = json['matchOver'] as bool;
    m.firstInningsScore = json['firstInningsScore'] as int?;
    m.firstInningsBattingTeam = json['firstInningsBattingTeam'] as String?;
    m.score = json['score'] as int;
    m.wickets = json['wickets'] as int;
    m.legalBalls = json['legalBalls'] as int;
    m.totalLegalBalls = json['totalLegalBalls'] as int;
    m.ballHistoryThisOver = (json['ballHistoryThisOver'] as List)
        .map((b) => BallEvent.fromJson(b as Map<String, dynamic>))
        .toList();
    m.ballLog = (json['ballLog'] as List? ?? [])
        .map((b) => BallLogEntry.fromJson(b as Map<String, dynamic>))
        .toList();
    m.completedInnings = (json['completedInnings'] as List? ?? [])
        .map((i) => InningsRecord.fromJson(i as Map<String, dynamic>))
        .toList();
    m.striker = json['striker'] as String?;
    m.nonStriker = json['nonStriker'] as String?;
    m.bowler = json['bowler'] as String?;
    m.previousOverBowler = json['previousOverBowler'] as String?;
    m.battingStats = (json['battingStats'] as Map).map((k, v) =>
        MapEntry(k as String, BattingStat.fromJson(v as Map<String, dynamic>)));
    m.bowlingStats = (json['bowlingStats'] as Map).map((k, v) =>
        MapEntry(k as String, BowlingStat.fromJson(v as Map<String, dynamic>)));
    m.extras = Extras.fromJson(json['extras'] as Map<String, dynamic>);
    return m;
  }
}