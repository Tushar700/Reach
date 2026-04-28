import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/mood_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/supabase_error_helper.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  final _noteController = TextEditingController();

  int _selectedMood = 3;
  int _energyLevel = 3;
  List<MoodLog> _recentLogs = [];
  bool _loading = true;
  bool _saving = false;
  bool _loggedToday = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await _supabase
          .from('mood_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(14);

      final logs = (data as List).map((e) => MoodLog.fromJson(e)).toList();
      final today = DateTime.now();
      final todayLog = logs.any((l) =>
          l.createdAt.year == today.year &&
          l.createdAt.month == today.month &&
          l.createdAt.day == today.day);

      setState(() {
        _recentLogs = logs;
        _loggedToday = todayLog;
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = friendlySupabaseError(e, feature: 'Mood tracking');
      });
    }
  }

  Future<void> _saveMood() async {
    setState(() => _saving = true);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _saving = false);
      return;
    }
    final moodOption = AppConstants.moodOptions.firstWhere((m) => m['value'] == _selectedMood);

    try {
      await _supabase.from('mood_logs').insert({
        'id': _uuid.v4(),
        'user_id': userId,
        'mood_value': _selectedMood,
        'mood_label': moodOption['label'],
        'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        'energy_level': _energyLevel,
        'created_at': DateTime.now().toIso8601String(),
      });

      _noteController.clear();
      _loadLogs();
      setState(() => _saving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mood logged'),
            backgroundColor: AppTheme.accentTeal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlySupabaseError(e, feature: 'Mood tracking')),
        ),
      );
    }
  }

  Color _moodColor(int value) {
    final opt = AppConstants.moodOptions.firstWhere((m) => m['value'] == value);
    return Color(opt['color'] as int);
  }

  String _moodEmoji(int value) {
    final opt = AppConstants.moodOptions.firstWhere((m) => m['value'] == value);
    return opt['emoji'] as String;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood & energy')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_loggedToday) ...[
                    _buildLogCard(),
                    const SizedBox(height: 24),
                  ] else ...[
                    _buildAlreadyLoggedBanner(),
                    const SizedBox(height: 24),
                  ],
                  if (_recentLogs.isNotEmpty) ...[
                    Text('Last 14 days', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    _buildMoodChart(),
                    const SizedBox(height: 24),
                    Text('Recent logs', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    ..._recentLogs.take(7).map((log) => _buildLogTile(log)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildAlreadyLoggedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppTheme.accentTeal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You already logged your mood today. Come back tomorrow!',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How are you feeling?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),

          // Mood selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: AppConstants.moodOptions.map((opt) {
              final isSelected = _selectedMood == opt['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = opt['value'] as int),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(opt['color'] as int).withValues(alpha: 0.2) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Color(opt['color'] as int) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(opt['emoji'] as String, style: TextStyle(fontSize: isSelected ? 30 : 24)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),
          Center(
            child: Text(
              AppConstants.moodOptions.firstWhere((m) => m['value'] == _selectedMood)['label'] as String,
              style: TextStyle(color: _moodColor(_selectedMood), fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),

          const SizedBox(height: 20),
          Text('Energy level', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 8),

          // Energy slider
          Row(
            children: [
              Text('Low', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryPurple,
                    inactiveTrackColor: AppTheme.darkBorder,
                    thumbColor: AppTheme.primaryPurple,
                    overlayColor: AppTheme.primaryPurple.withValues(alpha: 0.1),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _energyLevel.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (v) => setState(() => _energyLevel = v.round()),
                  ),
                ),
              ),
              Text('High', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
            ],
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Add a note (optional)...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
              filled: true,
              fillColor: AppTheme.darkBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _saveMood,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Log mood'),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChart() {
    // Simple bar chart of last 7 days
    final days = _recentLogs.take(7).toList().reversed.toList();
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((log) {
          final height = (log.moodValue / 5) * 60;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(_moodEmoji(log.moodValue), style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 28,
                height: height,
                decoration: BoxDecoration(
                  color: _moodColor(log.moodValue).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dayLabel(log.createdAt),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _dayLabel(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }

  Widget _buildLogTile(MoodLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Text(_moodEmoji(log.moodValue), style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.moodLabel, style: TextStyle(color: _moodColor(log.moodValue), fontWeight: FontWeight.w500, fontSize: 13)),
                if (log.note != null)
                  Text(log.note!, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${log.createdAt.day}/${log.createdAt.month}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

