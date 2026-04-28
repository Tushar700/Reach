import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/supabase_error_helper.dart';
import '../models/habit_model.dart';
import '../../../core/theme/app_theme.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  List<Habit> _habits = [];
  bool _loading = true;
  String? _errorMessage;

  final List<Map<String, String>> _emojiOptions = [
    {'emoji': '🏃', 'label': 'Exercise'},
    {'emoji': '📚', 'label': 'Read'},
    {'emoji': '💧', 'label': 'Hydrate'},
    {'emoji': '🧘', 'label': 'Meditate'},
    {'emoji': '✍️', 'label': 'Journal'},
    {'emoji': '😴', 'label': 'Sleep early'},
    {'emoji': '🥗', 'label': 'Eat healthy'},
    {'emoji': '💻', 'label': 'Study'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await _supabase
          .from('habits')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      setState(() {
        _habits = (data as List).map((e) => Habit.fromJson(e)).toList();
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = friendlySupabaseError(e, feature: 'Habit tracking');
      });
    }
  }

  Future<void> _toggleHabit(Habit habit) async {
    final today = DateTime.now();
    List<DateTime> updatedDates = List.from(habit.completedDates);
    int newStreak = habit.streakCount;

    if (habit.isCompletedToday) {
      updatedDates.removeWhere((d) => d.year == today.year && d.month == today.month && d.day == today.day);
      newStreak = (newStreak - 1).clamp(0, 999);
    } else {
      updatedDates.add(today);
      newStreak += 1;
    }

    try {
      await _supabase.from('habits').update({
        'completed_dates': updatedDates.map((d) => d.toIso8601String()).toList(),
        'streak_count': newStreak,
      }).eq('id', habit.id);

      _loadHabits();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlySupabaseError(e, feature: 'Habit tracking')),
        ),
      );
    }
  }

  void _showAddHabitSheet() {
    String title = '';
    String selectedEmoji = '⭐';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (context, setModal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New habit', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              // Emoji grid
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojiOptions.map((opt) {
                  final isSelected = selectedEmoji == opt['emoji'];
                  return GestureDetector(
                    onTap: () { setModal(() => selectedEmoji = opt['emoji']!); title = opt['label']!; },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryPurple.withValues(alpha: 0.2) : AppTheme.darkBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? AppTheme.primaryPurple : Colors.transparent),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(opt['emoji']!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(opt['label']!, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => title = v,
                decoration: InputDecoration(
                  hintText: 'Or type a custom habit...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: AppTheme.darkBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (title.isEmpty) return;
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final userId = _supabase.auth.currentUser?.id;
                  if (userId == null) return;
                  try {
                    await _supabase.from('habits').insert({
                      'id': _uuid.v4(),
                      'user_id': userId,
                      'title': title,
                      'emoji': selectedEmoji,
                      'frequency': 'daily',
                      'streak_count': 0,
                      'completed_dates': [],
                      'created_at': DateTime.now().toIso8601String(),
                    });
                    _loadHabits();
                    if (!mounted) return;
                    navigator.pop();
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          friendlySupabaseError(e, feature: 'Habit tracking'),
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Add habit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [IconButton(icon: const Icon(Icons.add, color: AppTheme.primaryPurpleLight), onPressed: _showAddHabitSheet)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
          : _habits.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.loop_rounded, size: 60, color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 16),
                  Text('No habits yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Build consistency, one habit at a time', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _habits.length,
                  itemBuilder: (context, i) {
                    final habit = _habits[i];
                    final done = habit.isCompletedToday;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: done ? AppTheme.primaryPurple.withValues(alpha: 0.1) : AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: done ? AppTheme.primaryPurple.withValues(alpha: 0.3) : AppTheme.darkBorder, width: 0.5),
                      ),
                      child: ListTile(
                        leading: Text(habit.emoji ?? '⭐', style: const TextStyle(fontSize: 24)),
                        title: Text(habit.title, style: TextStyle(color: done ? Colors.white.withValues(alpha: 0.5) : Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Row(children: [
                          Icon(Icons.local_fire_department, size: 13, color: done ? AppTheme.accentAmber : Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(width: 3),
                          Text('${habit.streakCount} day streak', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                        ]),
                        trailing: GestureDetector(
                          onTap: () => _toggleHabit(habit),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: done ? AppTheme.primaryPurple : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: done ? AppTheme.primaryPurple : Colors.white.withValues(alpha: 0.3), width: 1.5),
                            ),
                            child: done ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'habits_fab',
        onPressed: _showAddHabitSheet,
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

