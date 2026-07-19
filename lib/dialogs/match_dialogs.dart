import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const _dismissalTypes = [
  'Bowled',
  'Caught',
  'LBW',
  'Run Out',
  'Stumped',
  'Hit Wicket',
];

/// A simple dropdown-in-a-dialog picker. If the user picks "+ Add new
/// player", a text field appears in-place. Returns null on cancel.
Future<String?> _pickPlayerDialog({
  required BuildContext context,
  required String title,
  required List<String> options,
}) async {
  String? selected = options.isNotEmpty ? options.first : '__manual__';
  final manualController = TextEditingController();
  bool manual = options.isEmpty;

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: Text(title, style: const TextStyle(color: AppColors.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (options.isNotEmpty)
                DropdownButtonFormField<String>(
                  dropdownColor: AppColors.panel2,
                  value: manual ? '__manual__' : selected,
                  isExpanded: true,
                  items: [
                    ...options.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                    const DropdownMenuItem(
                      value: '__manual__',
                      child: Text('+ Add new player', style: TextStyle(color: AppColors.accent)),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      manual = v == '__manual__';
                      selected = v;
                    });
                  },
                ),
              if (manual)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: manualController,
                    style: const TextStyle(color: AppColors.text),
                    decoration: const InputDecoration(hintText: 'Player name'),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final result = manual ? manualController.text.trim() : (selected ?? '');
                Navigator.pop(ctx, result.isEmpty ? 'Player' : result);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      });
    },
  );
}

/// Result of the wicket dialog flow.
class WicketDialogResult {
  final String dismissal;
  final String whichEnd; // 'striker' or 'nonstriker'
  final int runsBeforeDismissal;
  final String nextBatsman;

  WicketDialogResult({
    required this.dismissal,
    required this.whichEnd,
    required this.runsBeforeDismissal,
    required this.nextBatsman,
  });
}

/// Shows the "how out" dialog (dismissal type, which end for run outs,
/// runs completed before a run out), then asks for the next batsman.
/// Returns null if cancelled at any step.
Future<WicketDialogResult?> showWicketDialog({
  required BuildContext context,
  required String strikerName,
  required String nonStrikerName,
  required List<String> availableBatsmen,
}) async {
  String dismissal = _dismissalTypes.first;
  String whichEnd = 'striker';
  int runsBefore = 0;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        final isRunOut = dismissal == 'Run Out';
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text('How out?', style: TextStyle(color: AppColors.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: AppColors.panel2,
                value: dismissal,
                isExpanded: true,
                items: _dismissalTypes
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => dismissal = v ?? dismissal),
              ),
              if (isRunOut) ...[
                const SizedBox(height: 12),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Which batsman is out?', style: AppTextStyles.small)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  dropdownColor: AppColors.panel2,
                  value: whichEnd,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'striker', child: Text(strikerName)),
                    DropdownMenuItem(value: 'nonstriker', child: Text(nonStrikerName)),
                  ],
                  onChanged: (v) => setState(() => whichEnd = v ?? whichEnd),
                ),
                const SizedBox(height: 12),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Runs completed before the run out', style: AppTextStyles.small)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  dropdownColor: AppColors.panel2,
                  value: runsBefore,
                  isExpanded: true,
                  items: List.generate(4, (i) => i)
                      .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                      .toList(),
                  onChanged: (v) => setState(() => runsBefore = v ?? runsBefore),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Next'),
            ),
          ],
        );
      });
    },
  );

  if (confirmed != true) return null;
  if (!context.mounted) return null;

  final nextBatsman = await _pickPlayerDialog(
    context: context,
    title: 'Next batsman',
    options: availableBatsmen,
  );
  if (nextBatsman == null) return null;

  return WicketDialogResult(
    dismissal: dismissal,
    whichEnd: whichEnd,
    runsBeforeDismissal: dismissal == 'Run Out' ? runsBefore : 0,
    nextBatsman: nextBatsman,
  );
}

Future<String?> showChangeBowlerDialog({
  required BuildContext context,
  required List<String> options,
}) {
  return _pickPlayerDialog(context: context, title: 'Select bowler', options: options);
}

/// Lets the user pick which end to replace (striker/non-striker) and
/// who comes in. Returns (which, name) or null if cancelled.
Future<({String which, String name})?> showChangeBatsmanDialog({
  required BuildContext context,
  required List<String> options,
}) async {
  String which = 'striker';

  final pickedWhich = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text('Change / retire batsman',
              style: TextStyle(color: AppColors.text)),
          content: DropdownButtonFormField<String>(
            dropdownColor: AppColors.panel2,
            value: which,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'striker', child: Text('Striker')),
              DropdownMenuItem(value: 'nonstriker', child: Text('Non-striker')),
            ],
            onChanged: (v) => setState(() => which = v ?? which),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, which),
              child: const Text('Next'),
            ),
          ],
        );
      });
    },
  );

  if (pickedWhich == null) return null;
  if (!context.mounted) return null;

  final name = await _pickPlayerDialog(
    context: context,
    title: 'New batsman',
    options: options,
  );
  if (name == null) return null;

  return (which: pickedWhich, name: name);
}

/// Prompts for a small run count (used for byes / leg byes), 1-6.
Future<int?> showRunCountDialog({
  required BuildContext context,
  required String title,
}) async {
  int value = 1;
  return showDialog<int>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: Text(title, style: const TextStyle(color: AppColors.text)),
          content: DropdownButtonFormField<int>(
            dropdownColor: AppColors.panel2,
            value: value,
            items: List.generate(6, (i) => i + 1)
                .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                .toList(),
            onChanged: (v) => setState(() => value = v ?? value),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, value),
              child: const Text('Confirm'),
            ),
          ],
        );
      });
    },
  );
}

/// Prompts for extra runs run/scored on top of a wide or no-ball (0-6).
/// Used so wides and no-balls can carry additional runs, same as a real
/// scorebook (byes run on a wide, or the batsman hitting a no ball for four).
Future<int?> showExtraRunsOnIllegalBallDialog({
  required BuildContext context,
  required String title,
}) async {
  int value = 0;
  return showDialog<int>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: Text(title, style: const TextStyle(color: AppColors.text)),
          content: DropdownButtonFormField<int>(
            dropdownColor: AppColors.panel2,
            value: value,
            items: List.generate(7, (i) => i)
                .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                .toList(),
            onChanged: (v) => setState(() => value = v ?? value),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, value),
              child: const Text('Confirm'),
            ),
          ],
        );
      });
    },
  );
}