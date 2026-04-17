import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';

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

final mentorServiceProvider = Provider<MentorService>((ref) => MentorService());

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
  final _supabase = Supabase.instance.client;
  String get _userId => _supabase.auth.currentUser!.id;

  Future<String> sendMessage(String userMessage, List<ChatMessage> history) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY']!;
    final model = dotenv.env['OPENROUTER_MODEL'] ?? 'mistralai/mistral-7b-instruct';

    // Build messages with memory (last N messages)
    final recentHistory = history.length > AppConstants.maxMentorMemory
        ? history.sublist(history.length - AppConstants.maxMentorMemory)
        : history;

    final messages = [
      {'role': 'system', 'content': AppConstants.mentorSystemPrompt},
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
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('OpenAI error: ${response.statusCode} ${response.body}');
    }
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
