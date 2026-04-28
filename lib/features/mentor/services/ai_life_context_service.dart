import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../habits/models/habit_model.dart';
import '../../mood/models/mood_model.dart';
import '../../personality/models/personality_model.dart';
import '../../tasks/models/task_model.dart';

final aiLifeContextServiceProvider = Provider<AiLifeContextService>(
  (ref) => AiLifeContextService(),
);

class AiLifeContextSnapshot {
  final List<Task> tasks;
  final List<Habit> habits;
  final List<MoodLog> moodLogs;
  final PersonalityProfile? personality;

  const AiLifeContextSnapshot({
    required this.tasks,
    required this.habits,
    required this.moodLogs,
    required this.personality,
  });

  String toPromptContext() {
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();
    final completedHabitsToday = habits.where((h) => h.isCompletedToday).toList();
    final latestMood = moodLogs.isEmpty ? null : moodLogs.first;

    final taskLines = pendingTasks.take(5).map((t) => '- ${t.title} (${t.priority ?? 'medium'})').join('\n');
    final habitLines = habits.take(5).map((h) {
      final status = h.isCompletedToday ? 'done today' : 'not done today';
      return '- ${h.title} ${h.emoji ?? '⭐'} | streak ${h.streakCount} | $status';
    }).join('\n');

    final moodSummary = latestMood == null
        ? 'No mood logged recently.'
        : 'Latest mood: ${latestMood.moodLabel} (${latestMood.moodValue}/5), energy ${latestMood.energyLevel}/5'
            '${latestMood.note == null ? '' : ', note: ${latestMood.note}'}';

    final personalitySummary = personality == null
        ? 'No personality profile yet.'
        : 'Mentor tone: ${personality!.computedMentorTone}, '
            'discipline ${personality!.disciplineScore.round()}, '
            'focus ${personality!.focusScore.round()}, '
            'consistency ${personality!.consistencyScore.round()}, '
            'motivation ${personality!.motivationScore.round()}, '
            'energy ${personality!.energyScore.round()}.';

    return '''
APP CONTEXT
- Tasks: ${tasks.length} total, ${pendingTasks.length} pending, ${completedTasks.length} completed.
${taskLines.isEmpty ? '- No pending tasks.' : taskLines}
- Habits: ${habits.length} total, ${completedHabitsToday.length} completed today.
${habitLines.isEmpty ? '- No habits yet.' : habitLines}
- Mood: $moodSummary
- Personality: $personalitySummary
''';
  }
}

class AiLifeContextService {
  final _supabase = Supabase.instance.client;

  String get _userId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to use AI context.');
    }
    return userId;
  }

  Future<AiLifeContextSnapshot> buildSnapshot() async {
    final tasksFuture = _supabase
        .from('tasks')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    final habitsFuture = _supabase
        .from('habits')
        .select()
        .eq('user_id', _userId)
        .order('created_at');
    final moodsFuture = _supabase
        .from('mood_logs')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .limit(14);
    final personalityFuture = _supabase
        .from('personality_scores')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    final results = await Future.wait([
      tasksFuture,
      habitsFuture,
      moodsFuture,
      personalityFuture,
    ]);

    final tasks = (results[0] as List).map((e) => Task.fromJson(e)).toList();
    final habits = (results[1] as List).map((e) => Habit.fromJson(e)).toList();
    final moods = (results[2] as List).map((e) => MoodLog.fromJson(e)).toList();
    final personalityJson = results[3] as Map<String, dynamic>?;

    return AiLifeContextSnapshot(
      tasks: tasks,
      habits: habits,
      moodLogs: moods,
      personality: personalityJson == null ? null : PersonalityProfile.fromJson(personalityJson),
    );
  }
}
