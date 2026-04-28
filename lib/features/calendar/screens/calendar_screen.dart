import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _supabase = Supabase.instance.client;
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<String, List<Map<String, dynamic>>> _events = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadEvents(); }

  Future<void> _loadEvents() async {
    final userId = _supabase.auth.currentUser!.id;
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    final tasks = await _supabase.from('tasks').select().eq('user_id', userId)
        .gte('created_at', firstDay.toIso8601String())
        .lte('created_at', lastDay.toIso8601String());

    final moods = await _supabase.from('mood_logs').select().eq('user_id', userId)
        .gte('created_at', firstDay.toIso8601String())
        .lte('created_at', lastDay.toIso8601String());

    final Map<String, List<Map<String, dynamic>>> events = {};

    for (final t in (tasks as List)) {
      final dt = DateTime.parse(t['created_at']);
      final key = '${dt.year}-${dt.month}-${dt.day}';
      events.putIfAbsent(key, () => []);
      events[key]!.add({'type': 'task', 'title': t['title'], 'done': t['is_completed']});
    }
    for (final m in (moods as List)) {
      final dt = DateTime.parse(m['created_at']);
      final key = '${dt.year}-${dt.month}-${dt.day}';
      events.putIfAbsent(key, () => []);
      events[key]!.add({'type': 'mood', 'title': 'Mood: ${m['mood_label']}', 'value': m['mood_value']});
    }

    setState(() { _events = events; _loading = false; });
  }

  List<Map<String, dynamic>> get _selectedEvents {
    final key = '${_selectedDay.year}-${_selectedDay.month}-${_selectedDay.day}';
    return _events[key] ?? [];
  }

  void _prevMonth() { setState(() { _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1); _loading = true; }); _loadEvents(); }
  void _nextMonth() { setState(() { _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1); _loading = true; }); _loadEvents(); }

  bool _isToday(DateTime d) { final t = DateTime.now(); return d.day == t.day && d.month == t.month && d.year == t.year; }
  bool _isSelected(DateTime d) => d.day == _selectedDay.day && d.month == _selectedDay.month && d.year == _selectedDay.year;
  bool _hasEvents(DateTime d) { final key = '${d.year}-${d.month}-${d.day}'; return _events.containsKey(key) && _events[key]!.isNotEmpty; }

  @override
  Widget build(BuildContext context) {
    final monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          // Month header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              GestureDetector(onTap: _prevMonth, child: Container(padding: const EdgeInsets.all(8), decoration: glassCard(radius: 10), child: const Icon(Icons.chevron_left, color: Colors.white, size: 20))),
              Expanded(child: Center(child: Text('${monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)))),
              GestureDetector(onTap: _nextMonth, child: Container(padding: const EdgeInsets.all(8), decoration: glassCard(radius: 10), child: const Icon(Icons.chevron_right, color: Colors.white, size: 20))),
            ]),
          ),

          // Day labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: ['S','M','T','W','T','F','S'].map((d) =>
              Expanded(child: Center(child: Text(d, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.w600))))
            ).toList()),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
                    itemCount: startWeekday + daysInMonth,
                    itemBuilder: (context, i) {
                      if (i < startWeekday) return const SizedBox.shrink();
                      final day = DateTime(_focusedMonth.year, _focusedMonth.month, i - startWeekday + 1);
                      final today = _isToday(day);
                      final selected = _isSelected(day);
                      final hasEv = _hasEvents(day);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDay = day),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.primaryPurple : today ? AppTheme.primaryPurple.withOpacity(0.15) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(alignment: Alignment.center, children: [
                            Text('${day.day}', style: TextStyle(
                              color: selected ? Colors.white : today ? AppTheme.primaryPurpleLight : Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: selected || today ? FontWeight.w700 : FontWeight.w400,
                            )),
                            if (hasEv && !selected) Positioned(bottom: 4, child: Container(width: 4, height: 4, decoration: BoxDecoration(color: AppTheme.accentTeal, shape: BoxShape.circle))),
                          ]),
                        ),
                      );
                    },
                  ),
                ),

          const Divider(color: Color(0xFF252840), height: 24),

          // Selected day events
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.event_note_rounded, size: 40, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 10),
                    Text('No activity on this day', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, i) {
                      final ev = _selectedEvents[i];
                      final isTask = ev['type'] == 'task';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: glassCard(radius: 12),
                        child: Row(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: (isTask ? AppTheme.primaryPurple : AppTheme.accentAmber).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(isTask ? Icons.check_circle_outline_rounded : Icons.mood_rounded, color: isTask ? AppTheme.primaryPurpleLight : AppTheme.accentAmber, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(ev['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 13))),
                          if (isTask && ev['done'] == true) const Icon(Icons.check, color: Color(0xFF4ADE80), size: 16),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
