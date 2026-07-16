// Core data models used across the cricket scoreboard app.

class Team {
  String name;
  List<String> players;

  Team({required this.name, List<String>? players}) : players = players ?? [];

  Map<String, dynamic> toJson() => {'name': name, 'players': players};

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    name: json['name'] as String,
    players: List<String>.from(json['players'] as List),
  );
}

class BattingStat {
  int runs;
  int balls;
  int fours;
  int sixes;
  bool out;
  String howOut;

  BattingStat({
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.out = false,
    this.howOut = '',
  });

  Map<String, dynamic> toJson() => {
    'runs': runs,
    'balls': balls,
    'fours': fours,
    'sixes': sixes,
    'out': out,
    'howOut': howOut,
  };

  factory BattingStat.fromJson(Map<String, dynamic> json) => BattingStat(
    runs: json['runs'] as int,
    balls: json['balls'] as int,
    fours: json['fours'] as int,
    sixes: json['sixes'] as int,
    out: json['out'] as bool,
    howOut: json['howOut'] as String,
  );
}

class BowlingStat {
  int legalBalls;
  int runs;
  int wickets;

  BowlingStat({this.legalBalls = 0, this.runs = 0, this.wickets = 0});

  String get oversDisplay => '${legalBalls ~/ 6}.${legalBalls % 6}';

  Map<String, dynamic> toJson() =>
      {'legalBalls': legalBalls, 'runs': runs, 'wickets': wickets};

  factory BowlingStat.fromJson(Map<String, dynamic> json) => BowlingStat(
    legalBalls: json['legalBalls'] as int,
    runs: json['runs'] as int,
    wickets: json['wickets'] as int,
  );
}

/// A single delivery shown as a chip in the "this over" strip.
class BallEvent {
  final String label;
  final String kind; // '', 'four', 'six', 'wd', 'nb', 'w'

  BallEvent(this.label, this.kind);

  Map<String, dynamic> toJson() => {'label': label, 'kind': kind};

  factory BallEvent.fromJson(Map<String, dynamic> json) =>
      BallEvent(json['label'] as String, json['kind'] as String);
}

class Extras {
  int wd;
  int nb;
  int lb;
  int b;

  Extras({this.wd = 0, this.nb = 0, this.lb = 0, this.b = 0});

  int get total => wd + nb + lb + b;

  Map<String, dynamic> toJson() => {'wd': wd, 'nb': nb, 'lb': lb, 'b': b};

  factory Extras.fromJson(Map<String, dynamic> json) => Extras(
    wd: json['wd'] as int,
    nb: json['nb'] as int,
    lb: json['lb'] as int,
    b: json['b'] as int,
  );
}

/// One line of ball-by-ball commentary. The full innings log is kept in
/// order (first ball to last) so the whole innings can be scrolled
/// through from start to finish.
class BallLogEntry {
  final String overBall; // e.g. "3.4"
  final String striker;
  final String bowler;
  final String description; // e.g. "4 runs", "Wide + 1", "OUT - Bowled"
  final String scoreAfter; // e.g. "45/2"

  BallLogEntry({
    required this.overBall,
    required this.striker,
    required this.bowler,
    required this.description,
    required this.scoreAfter,
  });

  Map<String, dynamic> toJson() => {
    'overBall': overBall,
    'striker': striker,
    'bowler': bowler,
    'description': description,
    'scoreAfter': scoreAfter,
  };

  factory BallLogEntry.fromJson(Map<String, dynamic> json) => BallLogEntry(
    overBall: json['overBall'] as String,
    striker: json['striker'] as String,
    bowler: json['bowler'] as String,
    description: json['description'] as String,
    scoreAfter: json['scoreAfter'] as String,
  );
}

/// A frozen snapshot of one completed innings — used for the post-match
/// summary, man-of-the-match calculation, and the full ball-by-ball
/// replay screen.
class InningsRecord {
  final String battingTeam; // 'A' or 'B'
  final String bowlingTeam;
  final int score;
  final int wickets;
  final String oversStr;
  final Map<String, BattingStat> battingStats;
  final Map<String, BowlingStat> bowlingStats;
  final Extras extras;
  final List<BallLogEntry> ballLog;

  InningsRecord({
    required this.battingTeam,
    required this.bowlingTeam,
    required this.score,
    required this.wickets,
    required this.oversStr,
    required this.battingStats,
    required this.bowlingStats,
    required this.extras,
    required this.ballLog,
  });

  Map<String, dynamic> toJson() => {
    'battingTeam': battingTeam,
    'bowlingTeam': bowlingTeam,
    'score': score,
    'wickets': wickets,
    'oversStr': oversStr,
    'battingStats': battingStats.map((k, v) => MapEntry(k, v.toJson())),
    'bowlingStats': bowlingStats.map((k, v) => MapEntry(k, v.toJson())),
    'extras': extras.toJson(),
    'ballLog': ballLog.map((b) => b.toJson()).toList(),
  };

  factory InningsRecord.fromJson(Map<String, dynamic> json) => InningsRecord(
    battingTeam: json['battingTeam'] as String,
    bowlingTeam: json['bowlingTeam'] as String,
    score: json['score'] as int,
    wickets: json['wickets'] as int,
    oversStr: json['oversStr'] as String,
    battingStats: (json['battingStats'] as Map).map((k, v) =>
        MapEntry(k as String, BattingStat.fromJson(v as Map<String, dynamic>))),
    bowlingStats: (json['bowlingStats'] as Map).map((k, v) =>
        MapEntry(k as String, BowlingStat.fromJson(v as Map<String, dynamic>))),
    extras: Extras.fromJson(json['extras'] as Map<String, dynamic>),
    ballLog: (json['ballLog'] as List)
        .map((b) => BallLogEntry.fromJson(b as Map<String, dynamic>))
        .toList(),
  );
}

/// One player's combined performance across the whole match — used to
/// rank candidates for man of the match and best-performance callouts.
class PlayerPerformance {
  final String name;
  int runs = 0;
  int ballsFaced = 0;
  int fours = 0;
  int sixes = 0;
  int inningsBatted = 0;
  int wickets = 0;
  int runsConceded = 0;
  int ballsBowled = 0;

  PlayerPerformance(this.name);

  double get strikeRate => ballsFaced > 0 ? (runs / ballsFaced) * 100 : 0;
  String get oversBowled => '${ballsBowled ~/ 6}.${ballsBowled % 6}';
  double get economy => ballsBowled > 0 ? runsConceded / (ballsBowled / 6) : 0;

  /// Simple weighted score used only to rank players against each other
  /// for "man of the match" — not an official cricket rating.
  double get impactPoints =>
      runs * 1.0 + fours * 1.0 + sixes * 1.5 + wickets * 20.0 - (runsConceded * 0.2);
}