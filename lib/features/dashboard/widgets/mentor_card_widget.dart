import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class MentorCardWidget extends StatefulWidget {
  const MentorCardWidget({super.key});

  @override
  State<MentorCardWidget> createState() => _MentorCardWidgetState();
}

class _MentorCardWidgetState extends State<MentorCardWidget> {
  String _message = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyMessage();
  }

  Future<void> _loadDailyMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = 'aria_daily_${today.year}_${today.month}_${today.day}';
    final cached = prefs.getString(key);

    if (cached != null) {
      setState(() { _message = cached; _loading = false; });
      return;
    }

    // Generate fresh daily message
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final name = user?.userMetadata?['full_name']?.toString().split(' ').first ?? 'there';
      final hour = DateTime.now().hour;
      final timeOfDay = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';

      final response = await http.post(
        Uri.parse('${AppConstants.openRouterBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['OPENROUTER_API_KEY']}',
          'HTTP-Referer': 'https://ai-life-os.app',
          'X-Title': 'AI Life OS',
        },
        body: jsonEncode({
          'model': dotenv.env['OPENROUTER_MODEL'] ?? 'mistralai/mistral-7b-instruct',
          'messages': [
            {'role': 'system', 'content': AppConstants.mentorSystemPrompt},
            {
              'role': 'user',
              'content': 'Give $name a brief, personalised $timeOfDay message. 1-2 sentences max. Be warm and specific to the time of day. End with one small actionable nudge.',
            }
          ],
          'max_tokens': 80,
          'temperature': 0.9,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final msg = data['choices'][0]['message']['content'].trim();
        await prefs.setString(key, msg);
        if (mounted) setState(() { _message = msg; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _message = 'Ready to make today count? Start with one small win.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.mentor),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryPurple, AppTheme.primaryPurpleDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Text('ARIA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.6), size: 18),
              ],
            ),
            const SizedBox(height: 14),
            _loading
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerLine(double.infinity),
                      const SizedBox(height: 6),
                      _shimmerLine(200),
                    ],
                  )
                : Text(
                    _message,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                  ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Chat with ARIA', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerLine(double width) => Container(
    height: 13,
    width: width,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

