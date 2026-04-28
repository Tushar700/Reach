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
import '../../mood/screens/mood_screen.dart';
import '../../personality/engine/personality_engine.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

// ── Inherited widget — passes animated accent color to all children ───────────
class AccentColor extends InheritedWidget {
  const AccentColor({super.key, required this.color, required super.child});

  final Color color;

  static Color of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AccentColor>()!
        .color;
  }

  @override
  bool updateShouldNotify(AccentColor old) => color != old.color;
}

// ── Dashboard ─────────────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _pulseController;
  late final Animation<Color?> _accentAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Smooth cycle: purple → teal → amber → purple
    _accentAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: AppTheme.primaryPurple, end: AppTheme.primaryPurpleLight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: AppTheme.primaryPurpleLight, end: AppTheme.accentTeal),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: AppTheme.accentTeal, end: const Color(0xFF5DCAA5)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: const Color(0xFF5DCAA5), end: AppTheme.accentAmber),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: AppTheme.accentAmber, end: AppTheme.primaryPurple),
        weight: 2,
      ),
    ]).animate(_pulseController);

    PersonalityEngine().recalculate();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _accentAnimation,
      builder: (context, _) {
        final accent = _accentAnimation.value ?? AppTheme.primaryPurple;

        return AccentColor(
          color: accent,
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: const [
                _HomeTab(),
                TasksScreen(),
                HabitsScreen(),
                MoodScreen(),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightSurface,
                border: Border(
                  top: BorderSide(color: accent.withOpacity(0.2), width: 0.5),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: accent,
                unselectedItemColor: const Color(0xFFB4B2A9),
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
          ),
        );
      },
    );
  }
}

// ── Home tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AccentColor.of(context);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ?? 'there';
    final firstName = name.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: AppTheme.lightBg,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: const TextStyle(
                color: Color(0xFF888780),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              firstName,
              style: const TextStyle(
                color: Color(0xFF2C2C2A),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome, color: accent),
            tooltip: 'Talk to ARIA',
            onPressed: () => context.push(AppRoutes.mentor),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFB4B2A9), size: 20),
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
        color: accent,
        backgroundColor: AppTheme.lightSurface,
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