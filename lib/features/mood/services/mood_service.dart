import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../models/mood_model.dart';

final moodServiceProvider = Provider<MoodService>((ref) => MoodService());

final recentMoodLogsProvider = FutureProvider<List<MoodLog>>((ref) async {
  return ref.watch(moodServiceProvider).getRecentLogs();
});

class MoodService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  String get _userId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to manage mood logs.');
    }
    return userId;
  }

  Future<List<MoodLog>> getRecentLogs({int limit = 14}) async {
    final data = await _supabase
        .from('mood_logs')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) => MoodLog.fromJson(e)).toList();
  }

  Future<bool> hasLoggedToday() async {
    final logs = await getRecentLogs(limit: 14);
    final today = DateTime.now();
    return logs.any(
      (l) =>
          l.createdAt.year == today.year &&
          l.createdAt.month == today.month &&
          l.createdAt.day == today.day,
    );
  }

  Future<MoodLog> logMood({
    required int moodValue,
    int energyLevel = 3,
    String? note,
  }) async {
    final moodOption = AppConstants.moodOptions.firstWhere(
      (m) => m['value'] == moodValue,
      orElse: () => AppConstants.moodOptions.firstWhere((m) => m['value'] == 3),
    );

    final now = DateTime.now();
    final data = await _supabase.from('mood_logs').insert({
      'id': _uuid.v4(),
      'user_id': _userId,
      'mood_value': moodValue,
      'mood_label': moodOption['label'],
      'note': note == null || note.trim().isEmpty ? null : note.trim(),
      'energy_level': energyLevel,
      'created_at': now.toIso8601String(),
    }).select().single();

    return MoodLog.fromJson(data);
  }
}
