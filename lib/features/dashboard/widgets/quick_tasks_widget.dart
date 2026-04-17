import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../tasks/models/task_model.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class QuickTasksWidget extends StatefulWidget {
  const QuickTasksWidget({super.key});

  @override
  State<QuickTasksWidget> createState() => _QuickTasksWidgetState();
}

class _QuickTasksWidgetState extends State<QuickTasksWidget> {
  final _supabase = Supabase.instance.client;
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .eq('is_completed', false)
        .order('created_at', ascending: false)
        .limit(4);
    setState(() {
      _tasks = (data as List).map((e) => Task.fromJson(e)).toList();
      _loading = false;
    });
  }

  Future<void> _toggle(Task task) async {
    await _supabase.from('tasks').update({'is_completed': true}).eq('id', task.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Upcoming tasks', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push(AppRoutes.tasks),
              child: Text('See all', style: TextStyle(color: AppTheme.primaryPurpleLight, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder, width: 0.5)),
            child: Row(children: [
              Icon(Icons.check_circle, color: AppTheme.accentTeal, size: 18),
              const SizedBox(width: 10),
              Text('All clear! No pending tasks.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            ]),
          )
        else
          ..._tasks.map((task) => GestureDetector(
            onTap: () => _toggle(task),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.darkBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(task.title, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.priority == 'high'
                          ? const Color(0xFFE24B4A)
                          : task.priority == 'medium'
                              ? AppTheme.accentAmber
                              : AppTheme.accentTeal,
                    ),
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }
}
