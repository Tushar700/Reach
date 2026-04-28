class PersonalityProfile {
  final String userId;
  final double disciplineScore;   // 0-100
  final double focusScore;        // 0-100
  final double consistencyScore;  // 0-100
  final double motivationScore;   // 0-100
  final double energyScore;       // 0-100
  final String motivationType;    // 'pressure' | 'inspiration'
  final String energyCycle;       // 'morning' | 'evening' | 'flexible'
  final String mentorTone;        // 'strict' | 'supportive' | 'analytical' | 'calm'
  final DateTime updatedAt;

  PersonalityProfile({
    required this.userId,
    this.disciplineScore = 50,
    this.focusScore = 50,
    this.consistencyScore = 50,
    this.motivationScore = 50,
    this.energyScore = 50,
    this.motivationType = 'inspiration',
    this.energyCycle = 'flexible',
    this.mentorTone = 'supportive',
    required this.updatedAt,
  });

  /// Derived mentor tone based on scores
  String get computedMentorTone {
    if (disciplineScore >= 70 && focusScore >= 70) return 'analytical';
    if (disciplineScore < 40) return 'strict';
    if (energyScore < 40) return 'calm';
    return 'supportive';
  }

  /// Overall life score (0-100)
  double get overallScore =>
      (disciplineScore + focusScore + consistencyScore + motivationScore + energyScore) / 5;

  factory PersonalityProfile.fromJson(Map<String, dynamic> json) => PersonalityProfile(
    userId: json['user_id'],
    disciplineScore: (json['discipline_score'] ?? 50).toDouble(),
    focusScore: (json['focus_score'] ?? 50).toDouble(),
    consistencyScore: (json['consistency_score'] ?? 50).toDouble(),
    motivationScore: (json['motivation_score'] ?? 50).toDouble(),
    energyScore: (json['energy_score'] ?? 50).toDouble(),
    motivationType: json['motivation_type'] ?? 'inspiration',
    energyCycle: json['energy_cycle'] ?? 'flexible',
    mentorTone: json['mentor_tone'] ?? 'supportive',
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'discipline_score': disciplineScore,
    'focus_score': focusScore,
    'consistency_score': consistencyScore,
    'motivation_score': motivationScore,
    'energy_score': energyScore,
    'motivation_type': motivationType,
    'energy_cycle': energyCycle,
    'mentor_tone': computedMentorTone,
    'updated_at': updatedAt.toIso8601String(),
  };

  /// Update scores based on recent behavior data
  PersonalityProfile recalculate({
    required int tasksCompleted,
    required int tasksTotal,
    required int habitStreakAvg,
    required double avgMood,
  }) {
    final double taskRate =
        tasksTotal > 0 ? (tasksCompleted / tasksTotal) * 100 : 50.0;
    final double habitScore = (habitStreakAvg / 7) * 100; // normalise to weekly
    final nextDisciplineScore = _lerp(disciplineScore, taskRate, 0.3);
    final nextFocusScore = _lerp(
      focusScore,
      taskRate * 0.8 + habitScore * 0.2,
      0.2,
    );
    final nextConsistencyScore = _lerp(consistencyScore, habitScore, 0.3);
    final nextMotivationScore = _lerp(motivationScore, avgMood * 20, 0.25);
    final nextEnergyScore = _lerp(energyScore, avgMood * 20, 0.2);

    final nextMentorTone = _computeMentorTone(
      disciplineScore: nextDisciplineScore,
      focusScore: nextFocusScore,
      energyScore: nextEnergyScore,
    );

    return PersonalityProfile(
      userId: userId,
      disciplineScore: nextDisciplineScore,
      focusScore: nextFocusScore,
      consistencyScore: nextConsistencyScore,
      motivationScore: nextMotivationScore,
      energyScore: nextEnergyScore,
      motivationType: motivationType,
      energyCycle: energyCycle,
      mentorTone: nextMentorTone,
      updatedAt: DateTime.now(),
    );
  }

  String _computeMentorTone({
    required double disciplineScore,
    required double focusScore,
    required double energyScore,
  }) {
    if (disciplineScore >= 70 && focusScore >= 70) return 'analytical';
    if (disciplineScore < 40) return 'strict';
    if (energyScore < 40) return 'calm';
    return 'supportive';
  }

  /// Weighted lerp for smooth score evolution
  double _lerp(double current, double target, double weight) =>
      (current * (1 - weight) + target * weight).clamp(0.0, 100.0).toDouble();
}
