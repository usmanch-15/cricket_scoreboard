import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_scoreboard/models/match_state.dart';

void main() {
  late MatchState s;

  setUp(() {
    s = MatchState();
    s.teamA.name = 'Team A';
    s.teamB.name = 'Team B';
    s.battingTeam = 'A';
    s.bowlingTeam = 'B';
    s.striker = 'Striker';
    s.nonStriker = 'NonStriker';
    s.bowler = 'Bowler';
    s.initPlayerStat('Striker');
    s.initPlayerStat('NonStriker');
    s.initBowlerStat('Bowler');
  });

  group('addRuns', () {
    test('even runs do not rotate strike', () {
      s.addRuns(2);
      expect(s.striker, 'Striker');
      expect(s.score, 2);
    });

    test('odd runs rotate strike', () {
      s.addRuns(1);
      expect(s.striker, 'NonStriker');
      expect(s.nonStriker, 'Striker');
    });

    test('four and six do not rotate strike, add correct fours/sixes', () {
      s.addRuns(4);
      expect(s.striker, 'Striker');
      expect(s.battingStats['Striker']!.fours, 1);

      s.addRuns(6);
      expect(s.striker, 'Striker');
      expect(s.battingStats['Striker']!.sixes, 1);
      expect(s.score, 10);
    });

    test('counts as a legal ball', () {
      s.addRuns(0);
      expect(s.legalBalls, 1);
      expect(s.totalLegalBalls, 1);
      expect(s.battingStats['Striker']!.balls, 1);
      expect(s.bowlingStats['Bowler']!.legalBalls, 1);
    });
  });

  group('addWide', () {
    test('adds 1 run, does not count as legal ball', () {
      s.addWide();
      expect(s.score, 1);
      expect(s.legalBalls, 0);
      expect(s.extras.wd, 1);
    });

    test('extra runs on a wide add to total and can rotate strike', () {
      s.addWide(extraRuns: 1);
      expect(s.score, 2);
      expect(s.extras.wd, 2);
      expect(s.striker, 'NonStriker'); // odd extra run rotates
    });
  });

  group('addNoBall', () {
    test('adds 1 run penalty, does not count as legal ball', () {
      s.addNoBall();
      expect(s.score, 1);
      expect(s.legalBalls, 0);
      expect(s.extras.nb, 1);
    });

    test('bat runs on no ball count toward batsman', () {
      s.addNoBall(batRuns: 4);
      expect(s.score, 5); // 1 penalty + 4 runs
      expect(s.battingStats['Striker']!.runs, 4);
      expect(s.battingStats['Striker']!.fours, 1);
    });
  });

  group('addLegBye / addBye', () {
    test('leg bye counts as legal ball but not batsman runs', () {
      s.addLegBye(2);
      expect(s.score, 2);
      expect(s.legalBalls, 1);
      expect(s.battingStats['Striker']!.runs, 0);
      expect(s.extras.lb, 2);
    });

    test('bye counts as legal ball but not batsman runs', () {
      s.addBye(1);
      expect(s.score, 1);
      expect(s.legalBalls, 1);
      expect(s.striker, 'NonStriker'); // odd run rotates
      expect(s.extras.b, 1);
    });
  });

  group('recordWicket', () {
    test('bowled wicket credits the bowler, does not rotate strike', () {
      s.recordWicket(dismissalType: 'Bowled', nextBatsman: 'NewBatsman');
      expect(s.wickets, 1);
      expect(s.striker, 'NewBatsman');
      expect(s.bowlingStats['Bowler']!.wickets, 1);
      expect(s.battingStats['Striker']!.out, true);
    });

    test('run out does not credit the bowler with a wicket', () {
      s.recordWicket(dismissalType: 'Run Out', nextBatsman: 'NewBatsman');
      expect(s.bowlingStats['Bowler']!.wickets, 0);
      expect(s.wickets, 1);
    });

    test('run out can dismiss the non-striker', () {
      s.recordWicket(
        dismissalType: 'Run Out',
        nextBatsman: 'NewBatsman',
        whichEnd: 'nonstriker',
      );
      expect(s.nonStriker, 'NewBatsman');
      expect(s.striker, 'Striker'); // unchanged
    });

    test('runs completed before a run out still count', () {
      s.recordWicket(
        dismissalType: 'Run Out',
        nextBatsman: 'NewBatsman',
        runsBeforeDismissal: 1,
      );
      expect(s.score, 1);
      expect(s.battingStats['Striker']!.runs, 1);
    });
  });

  group('checkOverComplete', () {
    test('rotates strike and resets after 6 legal balls', () {
      for (var i = 0; i < 6; i++) {
        s.addRuns(0);
      }
      final overDone = s.checkOverComplete();
      expect(overDone, true);
      expect(s.legalBalls, 0);
      expect(s.striker, 'NonStriker'); // ends swap between overs
      expect(s.previousOverBowler, 'Bowler');
    });

    test('does not complete before 6 legal balls', () {
      s.addRuns(0);
      s.addRuns(0);
      expect(s.checkOverComplete(), false);
    });
  });

  group('checkInningsEnd', () {
    test('ends when all out', () {
      s.totalWickets = 1;
      s.recordWicket(dismissalType: 'Bowled', nextBatsman: 'X');
      expect(s.checkInningsEnd(), true);
    });

    test('ends when overs are used up', () {
      s.totalOvers = 1;
      for (var i = 0; i < 6; i++) {
        s.addRuns(0);
      }
      expect(s.checkInningsEnd(), true);
    });

    test('second innings ends early once target is passed', () {
      s.innings = 2;
      s.firstInningsScore = 10;
      s.score = 11;
      expect(s.checkInningsEnd(), true);
    });

    test('second innings does not end on a tie', () {
      s.innings = 2;
      s.firstInningsScore = 10;
      s.score = 10;
      expect(s.checkInningsEnd(), false);
    });
  });

  group('undo', () {
    test('reverts the last scoring action', () {
      s.addRuns(4);
      expect(s.score, 4);
      s.undo();
      expect(s.score, 0);
      expect(s.canUndo, false);
    });

    test('does nothing when stack is empty', () {
      expect(s.canUndo, false);
      s.undo(); // should not throw
      expect(s.score, 0);
    });
  });

  group('toJson / fromJson round trip', () {
    test('preserves full state', () {
      s.addRuns(4);
      s.addWide(extraRuns: 1);
      s.recordWicket(dismissalType: 'Bowled', nextBatsman: 'NewBatsman');

      final json = s.toJson();
      final restored = MatchState.fromJson(json);

      expect(restored.score, s.score);
      expect(restored.wickets, s.wickets);
      expect(restored.striker, s.striker);
      expect(restored.battingStats.keys, s.battingStats.keys);
      expect(restored.extras.wd, s.extras.wd);
    });
  });
}