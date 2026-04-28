import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/supabase_error_helper.dart';
import '../models/personality_model.dart';

final personalityProvider = FutureProvider<PersonalityProfile>((ref) async {
  return PersonalityEngine().getOrCreate();
});

class PersonalityEngine {
  final _supabase = Supabase.instance.client;
  String get _userId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to load personality data.');
    }
    return userId;
  }

  Future<PersonalityProfile> getOrCreate() async {
    try {
      final data = await _supabase
          .from('personality_scores')
          .select()
          .eq('user_id', _userId)
          .single();
      return PersonalityProfile.fromJson(data);
    } catch (e) {
      // Create default profile on first run
      final profile = PersonalityProfile(
        userId: _userId,
        updatedAt: DateTime.now(),
      );
      if (friendlySupabaseError(e).contains('Supabase tables are missing')) {
        return profile;
      }
      await _supabase.from('personality_scores').insert({
        'user_id': _userId,
        ...profile.toJson(),
      });
      return profile;
    }
  }

  /// Called daily — recalculates scores from recent behavior
  Future<PersonalityProfile> recalculate() async {
    final profile = await getOrCreate();

    // Fetch last 7 days of data
    final since = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    final tasksData = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', _userId)
        .gte('created_at', since);

    final moodData = await _supabase
        .from('mood_logs')
        .select()
        .eq('user_id', _userId)
        .gte('created_at', since);

    final habitsData = await _supabase
        .from('habits')
        .select()
        .eq('user_id', _userId);

    final tasks = tasksData as List;
    final moods = moodData as List;
    final habits = habitsData as List;

    final tasksCompleted = tasks.where((t) => t['is_completed'] == true).length;
    final tasksTotal = tasks.length;
    final avgMood = moods.isEmpty
        ? 3.0
        : moods.map((m) => (m['mood_value'] as int).toDouble()).reduce((a, b) => a + b) / moods.length;
    final avgStreak = habits.isEmpty
        ? 0
        : (habits.map((h) => (h['streak_count'] as int)).reduce((a, b) => a + b) / habits.length).round();

    final updated = profile.recalculate(
      tasksCompleted: tasksCompleted,
      tasksTotal: tasksTotal,
      habitStreakAvg: avgStreak,
      avgMood: avgMood,
    );

    await _supabase.from('personality_scores').upsert({
      'user_id': _userId,
      ...updated.toJson(),
    });

    return updated;
  }

  /// Decision engine — what should the app do right now?
  Map<String, dynamic> getAdaptations(PersonalityProfile profile) {
    return {
      'simplifyUI': profile.overallScore < 35,
      'increaseChallenge': profile.overallScore > 75,
      'reduceTaskCount': profile.energyScore < 35,
      'showMotivation': profile.motivationScore < 45,
      'mentorTone': profile.computedMentorTone,
      'recommendFocus': profile.focusScore < 50,
      'celebrateStreak': profile.consistencyScore > 70,
    };
  }
}
