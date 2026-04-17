import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/mentor_card_widget.dart';
import '../widgets/stats_widget.dart';
import '../widgets/quick_tasks_widget.dart';
import '../widgets/habit_ring_widget.dart';
import '../widgets/mood_banner_widget.dart';
import '../../tasks/screens/tasks_screen.dart';
import '../../habits/screens/habits_screen.dart';
import '../../mentor/screens/mentor_chat_screen.dart';
import '../../mood/screens/mood_screen.dart';
import '../../personality/engine/personality_engine.dart';
import '../../personality/models/personality_model.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final _tabs = const [
    _HomeTab(),
    TasksScreen(),
    HabitsScreen(),
    MoodScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Recalculate personality scores in background
    PersonalityEngine().recalculate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          border: Border(top: BorderSide(color: AppTheme.darkBorder, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryPurpleLight,
          unselectedItemColor: const Color(0xFF4A4860),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.loop_rounded), label: 'Habits'),
            BottomNavigationBarItem(icon: Icon(Icons.mood), label: 'Mood'),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'there';
    final firstName = name.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$greeting,', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w400)),
            Text(firstName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppTheme.primaryPurpleLight),
            tooltip: 'Talk to ARIA',
            onPressed: () => context.push(AppRoutes.mentor),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white.withOpacity(0.4), size: 20),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await PersonalityEngine().recalculate();
          ref.invalidate(personalityProvider);
        },
        color: AppTheme.primaryPurple,
        backgroundColor: AppTheme.darkCard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: const [
            MoodBannerWidget(),
            SizedBox(height: 16),
            MentorCardWidget(),
            SizedBox(height: 16),
            StatsWidget(),
            SizedBox(height: 16),
            HabitRingWidget(),
            SizedBox(height: 16),
            QuickTasksWidget(),
          ],
        ),
      ),
    );
  }
}
