import 'package:flutter/material.dart';
import '../models/match_state.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _error;
  List<_HistoryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await SupabaseService.fetchAllMatches();
      final entries = <_HistoryEntry>[];
      for (final row in rows) {
        try {
          final state = MatchState.fromJson(row['state'] as Map<String, dynamic>);
          entries.add(_HistoryEntry(
            id: row['id'] as String,
            updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
            state: state,
          ));
        } catch (_) {
          // Skip any row that doesn't parse (e.g. from an older app version).
        }
      }
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete(_HistoryEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Delete this match from history?',
            style: TextStyle(color: AppColors.text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await SupabaseService.deleteMatch(entry.id);
      setState(() => _entries.remove(entry));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not delete: $e')));
      }
    }
  }

  String _subtitle(MatchState s) {
    if (s.battingTeam == null) return 'Setup in progress';
    if (s.matchOver) {
      final team1 = s.teamName(s.firstInningsBattingTeam!);
      final team2 = s.teamName(s.battingTeam!);
      final s1 = s.firstInningsScore ?? 0;
      final s2 = s.score;
      if (s2 > s1) {
        return '${s.teamName(s.battingTeam!)} won by ${s.totalWickets - s.wickets} wkt(s)';
      } else if (s1 > s2) {
        return '$team1 won by ${s1 - s2} run(s)';
      }
      return 'Match tied';
    }
    return 'In progress — Innings ${s.innings}, ${s.score}/${s.wickets} (${s.currentOversStr()} ov)';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]}, $hour12:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text('Match History'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Could not load history:\n$_error',
                style: AppTextStyles.small, textAlign: TextAlign.center),
          ),
        )
            : _entries.isEmpty
            ? const Center(
            child: Text('No matches saved yet.', style: AppTextStyles.small))
            : ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: _entries.length,
          itemBuilder: (ctx, i) {
            final e = _entries[i];
            final s = e.state;
            final teamsLabel = '${s.teamA.name} vs ${s.teamB.name}';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryDetailScreen(state: s),
                  ),
                ),
                title: Text(teamsLabel,
                    style: const TextStyle(color: AppColors.text, fontSize: 15)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${_subtitle(s)}\n${_formatDate(e.updatedAt)}',
                    style: AppTextStyles.small,
                  ),
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.muted),
                  onPressed: () => _delete(e),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryEntry {
  final String id;
  final DateTime? updatedAt;
  final MatchState state;

  _HistoryEntry({required this.id, required this.updatedAt, required this.state});
}