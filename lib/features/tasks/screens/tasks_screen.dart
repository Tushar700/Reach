import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/supabase_error_helper.dart';
import '../models/task_model.dart';
import '../services/tasks_service.dart';
import '../../../core/theme/app_theme.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _taskController = TextEditingController();
  String _selectedPriority = 'medium';

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add task', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: _taskController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'What do you need to do?',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: AppTheme.darkBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              // Priority selector
              Row(
                children: ['low', 'medium', 'high'].map((p) {
                  final isSelected = _selectedPriority == p;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() => _selectedPriority = p);
                      setState(() => _selectedPriority = p);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? _priorityColor(p).withValues(alpha: 0.2) : AppTheme.darkBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? _priorityColor(p) : Colors.transparent),
                      ),
                      child: Text(p, style: TextStyle(color: isSelected ? _priorityColor(p) : Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_taskController.text.trim().isEmpty) return;
                  final navigator = Navigator.of(context);
                  await ref.read(tasksServiceProvider).addTask(
                    _taskController.text.trim(),
                    priority: _selectedPriority,
                  );
                  _taskController.clear();
                  ref.invalidate(tasksProvider);
                  if (!mounted) return;
                  navigator.pop();
                },
                child: const Text('Add task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high': return const Color(0xFFE24B4A);
      case 'medium': return AppTheme.accentAmber;
      default: return AppTheme.accentTeal;
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryPurpleLight),
            onPressed: _showAddTaskSheet,
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              friendlySupabaseError(e, feature: 'Tasks'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 60, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('No tasks yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Tap + to add your first task', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13)),
                ],
              ),
            );
          }

          final pending = tasks.where((t) => !t.isCompleted).toList();
          final completed = tasks.where((t) => t.isCompleted).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionHeader('To do', pending.length),
                ...pending.map((t) => _taskTile(t)),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 8),
                _sectionHeader('Completed', completed.length),
                ...completed.map((t) => _taskTile(t)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tasks_fab',
        onPressed: _showAddTaskSheet,
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _taskTile(Task task) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE24B4A).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFE24B4A)),
      ),
      onDismissed: (_) async {
        await ref.read(tasksServiceProvider).deleteTask(task.id);
        ref.invalidate(tasksProvider);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.darkBorder, width: 0.5),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: GestureDetector(
            onTap: () async {
              await ref.read(tasksServiceProvider).toggleTask(task.id, !task.isCompleted);
              ref.invalidate(tasksProvider);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: task.isCompleted ? AppTheme.primaryPurple : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted ? AppTheme.primaryPurple : Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: task.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              color: task.isCompleted ? Colors.white.withValues(alpha: 0.35) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              decorationColor: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _priorityColor(task.priority ?? 'medium').withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              task.priority ?? 'medium',
              style: TextStyle(color: _priorityColor(task.priority ?? 'medium'), fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

