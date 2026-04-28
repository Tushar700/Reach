import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/habit_model.dart';

final habitsServiceProvider = Provider<HabitsService>((ref) => HabitsService());

final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  return ref.watch(habitsServiceProvider).getHabits();
});

class HabitsService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  String get _userId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to manage habits.');
    }
    return userId;
  }

  Future<List<Habit>> getHabits() async {
    final data = await _supabase
        .from('habits')
        .select()
        .eq('user_id', _userId)
        .order('created_at');
    return (data as List).map((e) => Habit.fromJson(e)).toList();
  }

  Future<Habit> addHabit(
    String title, {
    String emoji = '⭐',
    String frequency = 'daily',
  }) async {
    final now = DateTime.now();
    final data = await _supabase.from('habits').insert({
      'id': _uuid.v4(),
      'user_id': _userId,
      'title': title,
      'emoji': emoji,
      'frequency': frequency,
      'streak_count': 0,
      'completed_dates': <String>[],
      'created_at': now.toIso8601String(),
    }).select().single();

    return Habit.fromJson(data);
  }

  Future<void> toggleHabit(Habit habit) async {
    final today = DateTime.now();
    final updatedDates = List<DateTime>.from(habit.completedDates);
    var newStreak = habit.streakCount;

    if (habit.isCompletedToday) {
      updatedDates.removeWhere(
        (d) => d.year == today.year && d.month == today.month && d.day == today.day,
      );
      newStreak = (newStreak - 1).clamp(0, 999);
    } else {
      updatedDates.add(today);
      newStreak += 1;
    }

    await _supabase.from('habits').update({
      'completed_dates': updatedDates.map((d) => d.toIso8601String()).toList(),
      'streak_count': newStreak,
    }).eq('id', habit.id);
  }
}
