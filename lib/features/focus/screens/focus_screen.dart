import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  static const _modes = [
    {'label': 'Focus', 'minutes': 25, 'color': 0xFF6C63FF, 'icon': Icons.psychology_rounded},
    {'label': 'Short break', 'minutes': 5, 'color': 0xFF00D4AA, 'icon': Icons.coffee_rounded},
    {'label': 'Long break', 'minutes': 15, 'color': 0xFF4DA6FF, 'icon': Icons.self_improvement_rounded},
  ];

  int _modeIndex = 0;
  late int _seconds;
  Timer? _timer;
  bool _running = false;
  int _sessionsCompleted = 0;

  @override
  void initState() {
    super.initState();
    _seconds = (_modes[0]['minutes'] as int) * 60;
  }

  void _selectMode(int i) {
    _stop();
    setState(() {
      _modeIndex = i;
      _seconds = (_modes[i]['minutes'] as int) * 60;
    });
  }

  void _start() {
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _complete();
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _stop();
    setState(() => _seconds = (_modes[_modeIndex]['minutes'] as int) * 60);
  }

  void _complete() {
    _stop();
    if (_modeIndex == 0) setState(() => _sessionsCompleted++);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_modeIndex == 0 ? 'Session complete! 🎉' : 'Break over!', style: const TextStyle(color: Colors.white)),
        content: Text(
          _modeIndex == 0 ? 'Great focus session. Take a short break.' : 'Ready to focus again?',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _reset(); }, child: const Text('Reset')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
            onPressed: () { Navigator.pop(context); _selectMode(_modeIndex == 0 ? 1 : 0); },
            child: Text(_modeIndex == 0 ? 'Take break' : 'Start focus'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String get _timeStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = (_modes[_modeIndex]['minutes'] as int) * 60;
    return 1 - (_seconds / total);
  }

  @override
  Widget build(BuildContext context) {
    final mode = _modes[_modeIndex];
    final color = Color(mode['color'] as int);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus timer'),
        leading: const BackButton(),
        actions: [
          if (_sessionsCompleted > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Text('$_sessionsCompleted sessions', style: const TextStyle(color: AppTheme.primaryPurpleLight, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          // Mode selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(_modes.length, (i) {
                final m = _modes[i];
                final isSelected = _modeIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _selectMode(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(m['color'] as int).withOpacity(0.15) : AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Color(m['color'] as int) : AppTheme.darkBorder, width: isSelected ? 1 : 0.5),
                      ),
                      child: Column(children: [
                        Icon(m['icon'] as IconData, color: isSelected ? Color(m['color'] as int) : Colors.white.withOpacity(0.3), size: 18),
                        const SizedBox(height: 4),
                        Text(m['label'] as String, style: TextStyle(color: isSelected ? Color(m['color'] as int) : Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                );
              }),
            ),
          ),

          const Spacer(),

          // Timer ring
          SizedBox(
            width: 240, height: 240,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 220, height: 220,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.darkCard,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_timeStr, style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w700, letterSpacing: -2)),
                Text((mode['label'] as String).toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2)),
              ]),
            ]),
          ),

          const Spacer(),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(
                onTap: _reset,
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: AppTheme.darkCard, shape: BoxShape.circle, border: Border.all(color: AppTheme.darkBorder)),
                  child: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(0.5), size: 22),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _running ? _stop : _start,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _selectMode((_modeIndex + 1) % _modes.length),
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: AppTheme.darkCard, shape: BoxShape.circle, border: Border.all(color: AppTheme.darkBorder)),
                  child: Icon(Icons.skip_next_rounded, color: Colors.white.withOpacity(0.5), size: 22),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),
          Text(
            _running ? 'Stay focused. You\'ve got this.' : 'Press play to start your session',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
