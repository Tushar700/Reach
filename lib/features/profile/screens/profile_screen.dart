import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _notificationsEnabled = true;
  bool _dailyReminder = true;
  String _reminderTime = '09:00';

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      final data = await _supabase.from('profiles').select().eq('id', userId).single();
      setState(() { _profile = data; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  String get _initials {
    final name = _profile?['name'] as String? ?? _supabase.auth.currentUser?.userMetadata?['full_name'] as String? ?? 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String get _name => _profile?['name'] as String? ?? _supabase.auth.currentUser?.userMetadata?['full_name'] as String? ?? 'User';
  String get _email => _profile?['email'] as String? ?? _supabase.auth.currentUser?.email ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), leading: const BackButton()),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Avatar + name
                Center(
                  child: Column(children: [
                    Container(
                      width: 86, height: 86,
                      decoration: BoxDecoration(
                        gradient: AppTheme.purpleGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.darkBorderLight, width: 2),
                      ),
                      child: Center(child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(height: 14),
                    Text(_name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(_email, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                      child: const Text('Free plan', style: TextStyle(color: AppTheme.primaryPurpleLight, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ]),
                ),
                const SizedBox(height: 32),

                // Notifications
                _SectionLabel(label: 'Notifications'),
                _SettingsTile(
                  icon: Icons.notifications_rounded,
                  iconColor: AppTheme.accentAmber,
                  title: 'Enable notifications',
                  subtitle: 'Get nudges and reminders',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                    activeThumbColor: AppTheme.primaryPurple,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.alarm_rounded,
                  iconColor: AppTheme.accentTeal,
                  title: 'Daily check-in reminder',
                  subtitle: 'Remind me to log mood and tasks',
                  trailing: Switch(
                    value: _dailyReminder,
                    onChanged: (v) => setState(() => _dailyReminder = v),
                    activeThumbColor: AppTheme.primaryPurple,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.access_time_rounded,
                  iconColor: AppTheme.accentBlue,
                  title: 'Reminder time',
                  subtitle: _reminderTime,
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF3D4060)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (!context.mounted || picked == null) return;
                    setState(
                      () => _reminderTime =
                          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                    );
                  },
                ),
                const SizedBox(height: 20),

                // App settings
                _SectionLabel(label: 'App'),
                _SettingsTile(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: AppTheme.primaryPurpleLight,
                  title: 'ARIA mentor',
                  subtitle: 'Powered by OpenRouter AI',
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF3D4060)),
                ),
                _SettingsTile(
                  icon: Icons.bar_chart_rounded,
                  iconColor: AppTheme.accentCoral,
                  title: 'View analytics',
                  subtitle: 'See your progress over time',
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF3D4060)),
                  onTap: () => context.push(AppRoutes.analytics),
                ),
                const SizedBox(height: 20),

                // Account
                _SectionLabel(label: 'Account'),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: const Color(0xFF8B8FA8),
                  title: 'Privacy policy',
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF3D4060)),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFF8B8FA8),
                  title: 'Terms of service',
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF3D4060)),
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppTheme.accentCoral,
                  title: 'Sign out',
                  trailing: const SizedBox.shrink(),
                  onTap: () async {
                    await _supabase.auth.signOut();
                    if (!context.mounted) return;
                    context.go(AppRoutes.login);
                  },
                ),
                const SizedBox(height: 32),
                Center(child: Text('AI Life OS v1.0.0', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12))),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.iconColor, required this.title, this.subtitle, required this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: glassCard(radius: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            if (subtitle != null) Text(subtitle!, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ])),
          trailing,
        ]),
      ),
    );
  }
}
