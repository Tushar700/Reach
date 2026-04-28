import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../habits/services/habits_service.dart';
import '../../mood/models/mood_model.dart';
import '../../mood/services/mood_service.dart';
import '../../tasks/services/tasks_service.dart';
import 'ai_life_context_service.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content, required this.timestamp});

  Map<String, dynamic> toOpenAI() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: json['role'],
    content: json['content'],
    timestamp: DateTime.parse(json['created_at']),
  );
}

final mentorServiceProvider = Provider<MentorService>((ref) => MentorService(ref));

final chatHistoryProvider = StateNotifierProvider<ChatHistoryNotifier, List<ChatMessage>>((ref) {
  return ChatHistoryNotifier(ref.watch(mentorServiceProvider));
});

class ChatHistoryNotifier extends StateNotifier<List<ChatMessage>> {
  final MentorService _service;

  ChatHistoryNotifier(this._service) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _service.loadHistory();
    state = history;
  }

  Future<void> sendMessage(String userMessage) async {
    final userMsg = ChatMessage(role: 'user', content: userMessage, timestamp: DateTime.now());
    state = [...state, userMsg];

    final response = await _service.sendMessage(userMessage, state);

    final assistantMsg = ChatMessage(role: 'assistant', content: response, timestamp: DateTime.now());
    state = [...state, assistantMsg];

    // Save to Supabase
    await _service.saveMessage(userMsg);
    await _service.saveMessage(assistantMsg);
  }

  void clearHistory() {
    state = [];
    _service.clearHistory();
  }
}

class MentorService {
  final Ref _ref;
  final _supabase = Supabase.instance.client;
  MentorService(this._ref);

  String get _userId {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to use the mentor chat.');
    }
    return userId;
  }

  Future<String> sendMessage(String userMessage, List<ChatMessage> history) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY']!;
    final model = dotenv.env['OPENROUTER_MODEL'] ?? 'mistralai/mistral-7b-instruct';
    final contextSnapshot = await _ref.read(aiLifeContextServiceProvider).buildSnapshot();

    // Build messages with memory (last N messages)
    final recentHistory = history.length > AppConstants.maxMentorMemory
        ? history.sublist(history.length - AppConstants.maxMentorMemory)
        : history;

    final messages = [
      {
        'role': 'system',
        'content': '''
${AppConstants.mentorSystemPrompt}

You are connected to the user's app state.
Use the app context below to make your advice specific.

${contextSnapshot.toPromptContext()}

If the user asks you to change the app, reply as strict JSON with this shape:
{
  "reply": "short natural response for the user",
  "actions": [
    {"type": "add_task", "title": "Task title", "priority": "low|medium|high"},
    {"type": "add_habit", "title": "Habit title", "emoji": "⭐"},
    {"type": "log_mood", "mood_value": 1-5, "energy_level": 1-5, "note": "optional"}
  ]
}

If no app change is needed, still return JSON:
{"reply":"your response","actions":[]}

Never invent unsupported action types. Never include markdown fences.
''',
      },
      ...recentHistory.map((m) => m.toOpenAI()),
    ];

    final response = await http.post(
      Uri.parse('${AppConstants.openRouterBaseUrl}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://ai-life-os.app',
        'X-Title': 'AI Life OS',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'max_tokens': 300,
        'temperature': 0.75,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'].trim() as String;
      return _handleAiResponse(content, contextSnapshot);
    } else {
      throw Exception('OpenAI error: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> _handleAiResponse(
    String rawContent,
    AiLifeContextSnapshot contextSnapshot,
  ) async {
    Map<String, dynamic>? payload;
    try {
      payload = jsonDecode(rawContent) as Map<String, dynamic>;
    } catch (_) {
      return rawContent;
    }

    final reply = (payload['reply'] as String?)?.trim();
    final actions = payload['actions'] as List? ?? const [];
    final actionSummaries = <String>[];

    for (final action in actions) {
      if (action is! Map) continue;
      final type = action['type']?.toString();
      if (type == null) continue;

      switch (type) {
        case 'add_task':
          final title = action['title']?.toString().trim();
          if (title == null || title.isEmpty) break;
          final priority = _normalizePriority(action['priority']?.toString());
          await _ref.read(tasksServiceProvider).addTask(title, priority: priority);
          actionSummaries.add('Added task "$title".');
          _ref.invalidate(tasksProvider);
          break;
        case 'add_habit':
          final title = action['title']?.toString().trim();
          if (title == null || title.isEmpty) break;
          final emoji = action['emoji']?.toString().trim();
          await _ref.read(habitsServiceProvider).addHabit(
                title,
                emoji: emoji == null || emoji.isEmpty ? '⭐' : emoji,
              );
          actionSummaries.add('Added habit "$title".');
          _ref.invalidate(habitsProvider);
          break;
        case 'log_mood':
          final alreadyLoggedToday = contextSnapshot.moodLogs.any(_isToday);
          if (alreadyLoggedToday) {
            actionSummaries.add('Skipped mood log because today is already logged.');
            break;
          }

          final moodValue = _clampInt(action['mood_value'], min: 1, max: 5, fallback: 3);
          final energyLevel = _clampInt(action['energy_level'], min: 1, max: 5, fallback: 3);
          final note = action['note']?.toString();

          await _ref.read(moodServiceProvider).logMood(
                moodValue: moodValue,
                energyLevel: energyLevel,
                note: note,
              );
          actionSummaries.add('Logged today\'s mood.');
          _ref.invalidate(recentMoodLogsProvider);
          break;
      }
    }

    final safeReply = (reply == null || reply.isEmpty) ? rawContent : reply;
    if (actionSummaries.isEmpty) {
      return safeReply;
    }

    return '$safeReply\n\n${actionSummaries.join(' ')}';
  }

  String _normalizePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
      case 'high':
        return priority!.toLowerCase();
      default:
        return 'medium';
    }
  }

  int _clampInt(
    Object? value, {
    required int min,
    required int max,
    required int fallback,
  }) {
    final parsed = switch (value) {
      int n => n,
      String s => int.tryParse(s),
      _ => null,
    };
    if (parsed == null) return fallback;
    return parsed.clamp(min, max);
  }

  bool _isToday(MoodLog log) {
    final now = DateTime.now();
    return log.createdAt.year == now.year &&
        log.createdAt.month == now.month &&
        log.createdAt.day == now.day;
  }

  Future<List<ChatMessage>> loadHistory() async {
    try {
      final data = await _supabase
          .from('mentor_messages')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: true)
          .limit(AppConstants.maxMentorMemory);
      return (data as List).map((e) => ChatMessage.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMessage(ChatMessage msg) async {
    try {
      await _supabase.from('mentor_messages').insert({
        'user_id': _userId,
        'role': msg.role,
        'content': msg.content,
        'created_at': msg.timestamp.toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    await _supabase.from('mentor_messages').delete().eq('user_id', _userId);
  }
}
