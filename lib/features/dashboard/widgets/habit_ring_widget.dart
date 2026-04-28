import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';

class HabitRingWidget extends StatefulWidget {
  const HabitRingWidget({super.key});

  @override
  State<HabitRingWidget> createState() => _HabitRingWidgetState();
}

class _HabitRingWidgetState extends State<HabitRingWidget> {
  final _supabase = Supabase.instance.client;
  int _total = 0;
  int _completedToday = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await _supabase.from('habits').select().eq('user_id', userId);
      final habits = data as List;
      final today = DateTime.now();

      int completed = 0;
      for (final h in habits) {
        final dates = (h['completed_dates'] as List? ?? []);
        final doneToday = dates.any((d) {
          final dt = DateTime.parse(d.toString());
          return dt.year == today.year && dt.month == today.month && dt.day == today.day;
        });
        if (doneToday) completed++;
      }

      setState(() {
        _total = habits.length;
        _completedToday = completed;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _total == 0) return const SizedBox.shrink();

    final progress = _total > 0 ? _completedToday / _total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder, width: 0.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: AppTheme.darkBg,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentTeal),
                ),
                Text(
                  '$_completedToday/$_total',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Habits today', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  _completedToday == _total
                      ? 'All done! Great consistency.'
                      : '${_total - _completedToday} habit${_total - _completedToday == 1 ? '' : 's'} remaining',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          if (_completedToday == _total)
            const Text('🎉', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}

