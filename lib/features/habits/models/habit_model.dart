class Habit {
  final String id;
  final String userId;
  final String title;
  final String frequency; // 'daily', 'weekly'
  final String? emoji;
  final int streakCount;
  final List<DateTime> completedDates;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.frequency = 'daily',
    this.emoji,
    this.streakCount = 0,
    this.completedDates = const [],
    required this.createdAt,
  });

  bool get isCompletedToday {
    final today = DateTime.now();
    return completedDates.any((d) =>
      d.year == today.year && d.month == today.month && d.day == today.day);
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      frequency: json['frequency'] ?? 'daily',
      emoji: json['emoji'],
      streakCount: json['streak_count'] ?? 0,
      completedDates: (json['completed_dates'] as List? ?? [])
          .map((d) => DateTime.parse(d.toString()))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'frequency': frequency,
    'emoji': emoji,
    'streak_count': streakCount,
    'completed_dates': completedDates.map((d) => d.toIso8601String()).toList(),
  };
}
