import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class MoodBannerWidget extends StatefulWidget {
  const MoodBannerWidget({super.key});

  @override
  State<MoodBannerWidget> createState() => _MoodBannerWidgetState();
}

class _MoodBannerWidgetState extends State<MoodBannerWidget> {
  final _supabase = Supabase.instance.client;
  bool _loggedToday = false;
  int? _todayMood;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final userId = _supabase.auth.currentUser!.id;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();

    final data = await _supabase
        .from('mood_logs')
        .select()
        .eq('user_id', userId)
        .gte('created_at', start)
        .limit(1);

    if ((data as List).isNotEmpty) {
      setState(() { _loggedToday = true; _todayMood = data[0]['mood_value']; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedToday && _todayMood != null) {
      final opt = AppConstants.moodOptions.firstWhere((m) => m['value'] == _todayMood);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Color(opt['color'] as int).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(opt['color'] as int).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Text(opt['emoji'] as String, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text('Feeling ${(opt['label'] as String).toLowerCase()} today', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push(AppRoutes.mood),
              child: Text('Details', style: TextStyle(color: AppTheme.primaryPurpleLight, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push(AppRoutes.mood),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.darkBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Text('😐', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text('How are you feeling today?', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 18),
          ],
        ),
      ),
    );
  }
}
