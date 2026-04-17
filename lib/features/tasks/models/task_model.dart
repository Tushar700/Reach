class Task {
  final String id;
  final String userId;
  final String title;
  final bool isCompleted;
  final String? description;
  final String? priority; // 'low', 'medium', 'high'
  final DateTime? dueDate;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.isCompleted = false,
    this.description,
    this.priority = 'medium',
    this.dueDate,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      isCompleted: json['is_completed'] ?? false,
      description: json['description'],
      priority: json['priority'] ?? 'medium',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'is_completed': isCompleted,
    'description': description,
    'priority': priority,
    'due_date': dueDate?.toIso8601String(),
  };

  Task copyWith({bool? isCompleted, String? title, String? priority}) {
    return Task(
      id: id,
      userId: userId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      description: description,
      priority: priority ?? this.priority,
      dueDate: dueDate,
      createdAt: createdAt,
    );
  }
}
