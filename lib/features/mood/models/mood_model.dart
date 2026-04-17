class MoodLog {
  final String id;
  final String userId;
  final int moodValue; // 1-5
  final String moodLabel;
  final String? note;
  final int energyLevel; // 1-5
  final DateTime createdAt;

  MoodLog({
    required this.id,
    required this.userId,
    required this.moodValue,
    required this.moodLabel,
    this.note,
    this.energyLevel = 3,
    required this.createdAt,
  });

  factory MoodLog.fromJson(Map<String, dynamic> json) => MoodLog(
    id: json['id'],
    userId: json['user_id'],
    moodValue: json['mood_value'],
    moodLabel: json['mood_label'],
    note: json['note'],
    energyLevel: json['energy_level'] ?? 3,
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'mood_value': moodValue,
    'mood_label': moodLabel,
    'note': note,
    'energy_level': energyLevel,
    'created_at': createdAt.toIso8601String(),
  };
}
