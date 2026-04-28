import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/task_model.dart';

final tasksServiceProvider = Provider<TasksService>((ref) => TasksService());

final tasksProvider = FutureProvider<List<Task>>((ref) async {
  return ref.watch(tasksServiceProvider).getTasks();
});

class TasksService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  String get _userId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to manage tasks.');
    }
    return userId;
  }

  Future<List<Task>> getTasks() async {
    final data = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Task.fromJson(e)).toList();
  }

  Future<Task> addTask(String title, {String priority = 'medium'}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final data = await _supabase.from('tasks').insert({
      'id': id,
      'user_id': _userId,
      'title': title,
      'is_completed': false,
      'priority': priority,
      'created_at': now.toIso8601String(),
    }).select().single();
    return Task.fromJson(data);
  }

  Future<void> toggleTask(String id, bool isCompleted) async {
    await _supabase.from('tasks').update({'is_completed': isCompleted}).eq('id', id);
  }

  Future<void> deleteTask(String id) async {
    await _supabase.from('tasks').delete().eq('id', id);
  }
}
