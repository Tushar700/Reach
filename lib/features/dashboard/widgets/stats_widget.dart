import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../personality/engine/personality_engine.dart';
import '../../../core/theme/app_theme.dart';

class StatsWidget extends ConsumerWidget {
  const StatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(personalityProvider);

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Your scores', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Overall ${profile.overallScore.round()}',
                  style: const TextStyle(color: AppTheme.primaryPurpleLight, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ScoreCard(label: 'Discipline', score: profile.disciplineScore, color: AppTheme.primaryPurple),
              const SizedBox(width: 8),
              _ScoreCard(label: 'Focus', score: profile.focusScore, color: AppTheme.accentTeal),
              const SizedBox(width: 8),
              _ScoreCard(label: 'Consistency', score: profile.consistencyScore, color: AppTheme.accentAmber),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ScoreCard(label: 'Motivation', score: profile.motivationScore, color: AppTheme.accentCoral),
              const SizedBox(width: 8),
              _ScoreCard(label: 'Energy', score: profile.energyScore, color: const Color(0xFF7F77DD)),
              const SizedBox(width: 8),
              // Mentor tone chip
                Expanded(
                  child: Container(
                    height: 76,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.darkBorder, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ARIA tone', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                      Text(
                        profile.computedMentorTone,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _ScoreCard({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 76,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.darkBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  score.round().toString(),
                  style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('/100', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

