import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  int _tasksCompleted = 0;
  int _tasksPending = 0;
  int _habitsTotal = 0;
  int _habitsDoneToday = 0;
  double _avgMood = 0;
  List<Map<String, dynamic>> _moodWeek = [];
  List<Map<String, dynamic>> _taskWeek = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final userId = _supabase.auth.currentUser!.id;
    final since = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final tasks = await _supabase.from('tasks').select().eq('user_id', userId);
    final moods = await _supabase.from('mood_logs').select().eq('user_id', userId).gte('created_at', since).order('created_at');
    final habits = await _supabase.from('habits').select().eq('user_id', userId);

    final taskList = tasks as List;
    final moodList = moods as List;
    final habitList = habits as List;
    final today = DateTime.now();

    int habitsDone = 0;
    for (final h in habitList) {
      final dates = (h['completed_dates'] as List? ?? []);
      if (dates.any((d) { final dt = DateTime.parse(d.toString()); return dt.year == today.year && dt.month == today.month && dt.day == today.day; })) habitsDone++;
    }

    final moodWeek = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final dayMoods = moodList.where((m) { final dt = DateTime.parse(m['created_at']); return dt.day == day.day && dt.month == day.month; }).toList();
      final avg = dayMoods.isEmpty ? 0.0 : dayMoods.map((m) => (m['mood_value'] as int).toDouble()).reduce((a, b) => a + b) / dayMoods.length;
      return {'day': _dayLabel(day), 'value': avg};
    });

    final taskWeek = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final count = taskList.where((t) { if (t['is_completed'] != true) return false; final dt = DateTime.parse(t['created_at']); return dt.day == day.day && dt.month == day.month; }).length;
      return {'day': _dayLabel(day), 'value': count.toDouble()};
    });

    setState(() {
      _tasksCompleted = taskList.where((t) => t['is_completed'] == true).length;
      _tasksPending = taskList.where((t) => t['is_completed'] != true).length;
      _habitsTotal = habitList.length;
      _habitsDoneToday = habitsDone;
      _avgMood = moodList.isEmpty ? 0 : moodList.map((m) => (m['mood_value'] as int).toDouble()).reduce((a, b) => a + b) / moodList.length;
      _moodWeek = moodWeek;
      _taskWeek = taskWeek;
      _loading = false;
    });
  }

  String _dayLabel(DateTime dt) => ['M','T','W','T','F','S','S'][dt.weekday - 1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryPurple,
              backgroundColor: AppTheme.darkCard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(children: [
                    _SummaryCard(label: 'Tasks done', value: '$_tasksCompleted', gradient: AppTheme.purpleGradient, icon: Icons.check_circle_rounded),
                    const SizedBox(width: 10),
                    _SummaryCard(label: 'Pending', value: '$_tasksPending', gradient: AppTheme.coralGradient, icon: Icons.pending_actions_rounded),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _SummaryCard(label: 'Habits today', value: '$_habitsDoneToday/$_habitsTotal', gradient: AppTheme.tealGradient, icon: Icons.loop_rounded),
                    const SizedBox(width: 10),
                    _SummaryCard(label: 'Avg mood', value: _avgMood == 0 ? '—' : _avgMood.toStringAsFixed(1), gradient: AppTheme.amberGradient, icon: Icons.mood_rounded),
                  ]),
                  const SizedBox(height: 24),
                  _ChartCard(title: 'Mood — last 7 days', data: _moodWeek, maxValue: 5, color: AppTheme.accentAmber, emptyMsg: 'Log your mood daily to see the chart.'),
                  const SizedBox(height: 14),
                  _ChartCard(title: 'Tasks completed — last 7 days', data: _taskWeek, maxValue: _taskWeek.isEmpty ? 1 : _taskWeek.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b).clamp(1, 999).toDouble(), color: AppTheme.primaryPurple, emptyMsg: 'Complete tasks to see your productivity chart.'),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: glassCard(),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Today's progress", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _RingProgress(value: _habitsTotal > 0 ? _habitsDoneToday / _habitsTotal : 0, label: 'Habits', color: AppTheme.accentTeal),
                        _RingProgress(value: (_tasksCompleted + _tasksPending) > 0 ? _tasksCompleted / (_tasksCompleted + _tasksPending) : 0, label: 'Tasks', color: AppTheme.primaryPurple),
                        _RingProgress(value: _avgMood / 5, label: 'Mood', color: AppTheme.accentAmber),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final LinearGradient gradient;
  final IconData icon;
  const _SummaryCard({required this.label, required this.value, required this.gradient, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 22),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
        ])),
      ]),
    ),
  );
}

class _ChartCard extends StatelessWidget {
  final String title, emptyMsg;
  final List<Map<String, dynamic>> data;
  final double maxValue;
  final Color color;
  const _ChartCard({required this.title, required this.data, required this.maxValue, required this.color, required this.emptyMsg});
  @override
  Widget build(BuildContext context) {
    final hasData = data.any((d) => (d['value'] as double) > 0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: glassCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 16),
        if (!hasData)
          Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text(emptyMsg, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13))))
        else
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final val = d['value'] as double;
                final barH = maxValue > 0 ? (val / maxValue) * 80 : 0.0;
                final isLast = data.last == d;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (val > 0) Text(val == val.roundToDouble() ? val.toInt().toString() : val.toStringAsFixed(1), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600), curve: Curves.easeOut,
                        height: barH.clamp(4, 80),
                        decoration: BoxDecoration(
                          color: isLast ? color : color.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(d['day'] as String, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
      ]),
    );
  }
}

class _RingProgress extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  const _RingProgress({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    SizedBox(width: 64, height: 64,
      child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(value: value.clamp(0.0, 1.0), strokeWidth: 6, backgroundColor: AppTheme.darkBg, valueColor: AlwaysStoppedAnimation<Color>(color)),
        Text('${(value * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
    const SizedBox(height: 8),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
  ]);
}
