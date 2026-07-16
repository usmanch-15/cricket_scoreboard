import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// A panel-style card used to group a section of controls or info.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
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
          Text(title.toUpperCase(), style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// The glowing jumbotron-style score panel at the top of the match screen.
class LedScoreHeader extends StatelessWidget {
  final String teamLabel;
  final String scoreText;
  final String oversText;
  final String crrText;
  final List<BallEvent> thisOverBalls;

  const LedScoreHeader({
    super.key,
    required this.teamLabel,
    required this.scoreText,
    required this.oversText,
    required this.crrText,
    required this.thisOverBalls,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
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
          Text(teamLabel, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
          const SizedBox(height: 4),
          Text(scoreText, style: AppTextStyles.ledScore),
          const SizedBox(height: 4),
          Text(oversText, style: AppTextStyles.digital),
          const SizedBox(height: 2),
          Text(crrText, style: AppTextStyles.small, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: thisOverBalls.map((b) => BallChip(event: b)).toList(),
          ),
        ],
      ),
    );
  }
}

/// A single round chip representing one delivery (0,1,4,6,W,Wd,Nb...).
class BallChip extends StatelessWidget {
  final BallEvent event;

  const BallChip({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.panel2;
    Color fg = AppColors.text;
    Color border = AppColors.line;

    switch (event.kind) {
      case 'w':
        bg = AppColors.red;
        fg = Colors.white;
        border = AppColors.red;
        break;
      case 'four':
        bg = AppColors.blue;
        fg = Colors.white;
        border = AppColors.blue;
        break;
      case 'six':
        bg = AppColors.amber;
        fg = Colors.black;
        border = AppColors.amber;
        break;
      case 'wd':
      case 'nb':
        bg = const Color(0xFF5A4A1F);
        fg = const Color(0xFFFFD166);
        border = const Color(0xFF5A4A1F);
        break;
    }

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
      child: Text(
        event.label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Simple labelled stat row, e.g. "Wide  —  3".
class StatRow extends StatelessWidget {
  final String label;
  final String value;

  const StatRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}