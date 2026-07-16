import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'scoreboard_home.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  runApp(const CricketScoreboardApp());
}

class CricketScoreboardApp extends StatelessWidget {
  const CricketScoreboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cricket Scoreboard',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const ScoreboardHome(),
    );
  }
}