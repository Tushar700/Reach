import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class StreakBannerWidget extends StatefulWidget {
  const StreakBannerWidget({super.key});
  @override
  State<StreakBannerWidget> createState() => _StreakBannerWidgetState();
}

class _StreakBannerWidgetState extends State<StreakBannerWidget> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalDays = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
    _load();
  }

  Future<void> _load() async {
    final userId = _supabase.auth.currentUser!.id;
    final moodData = await _supabase.from('mood_logs').select('created_at').eq('user_id', userId).order('created_at');
    final taskData = await _supabase.from('tasks').select('created_at').eq('user_id', userId).eq('is_completed', true).order('created_at');

    final allDates = <String>{};
    for (final m in (moodData as List)) {
      final dt = DateTime.parse(m['created_at']);
      allDates.add('${dt.year}-${dt.month}-${dt.day}');
    }
    for (final t in (taskData as List)) {
      final dt = DateTime.parse(t['created_at']);
      allDates.add('${dt.year}-${dt.month}-${dt.day}');
    }

    final sortedDates = allDates.toList()..sort();
    int current = 0, longest = 0, streak = 0;
    DateTime? prev;

    for (final ds in sortedDates) {
      final parts = ds.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      if (prev == null || dt.difference(prev).inDays == 1) {
        streak++;
      } else if (dt.difference(prev).inDays > 1) {
        streak = 1;
      }
      if (streak > longest) longest = streak;
      prev = dt;
    }

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final yesterday = today.subtract(const Duration(days: 1));
    final yStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    if (!allDates.contains(todayStr) && !allDates.contains(yStr)) streak = 0;
    current = allDates.contains(todayStr) ? streak : (allDates.contains(yStr) ? streak : 0);

    if (mounted) setState(() { _currentStreak = current; _longestStreak = longest; _totalDays = allDates.length; });
  }

  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1530), Color(0xFF0F1220)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder, width: 0.5),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(scale: _currentStreak > 0 ? _pulseAnim.value : 1.0, child: child),
            child: Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                gradient: _currentStreak > 2
                    ? const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)])
                    : const LinearGradient(colors: [Color(0xFF3D4060), Color(0xFF252840)]),
                shape: BoxShape.circle,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_currentStreak > 0 ? '🔥' : '💤', style: const TextStyle(fontSize: 20)),
              ]),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('$_currentStreak', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                Text(' day streak', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ]),
              Text(
                _currentStreak == 0 ? 'Start logging today to build your streak' : 'Keep going — you\'re on a roll!',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _StatChip(label: 'Best', value: '$_longestStreak'),
            const SizedBox(height: 6),
            _StatChip(label: 'Total', value: '$_totalDays'),
          ]),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  const _StatChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.darkCardElevated, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
