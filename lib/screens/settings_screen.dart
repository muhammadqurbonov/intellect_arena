import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../language.dart';
import '../services/audio_service.dart';
import '../widgets/reveal.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeToggle;

  const SettingsScreen({
    super.key,
    required this.isDark,
    required this.onThemeToggle,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _audio = AudioService();
  late bool _sound;
  late bool _vibration;
  late bool _dark;

  @override
  void initState() {
    super.initState();
    _sound = _audio.soundEnabled;
    _vibration = _audio.vibrationEnabled;
    _dark = widget.isDark;
  }

  Future<void> _openInstagram() async {
    final uri =
        Uri.parse('https://www.instagram.com/m_qurbonov10?igsh=eXNneWJkeDh6eXlq');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Reveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(lang.t('language')),
                _LangTile(lang: lang),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Reveal(
            delayMs: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(lang.t('theme')),
                _ToggleTile(
                  icon: _dark ? Icons.dark_mode : Icons.light_mode,
                  label: _dark ? lang.t('dark_mode') : lang.t('light_mode'),
                  value: _dark,
                  onChanged: (v) {
                    setState(() => _dark = v);
                    widget.onThemeToggle(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Reveal(
            delayMs: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(lang.t('sound')),
                _ToggleTile(
                  icon: _sound ? Icons.volume_up : Icons.volume_off,
                  label: lang.t('sound'),
                  value: _sound,
                  onChanged: (v) {
                    setState(() => _sound = v);
                    _audio.setSoundEnabled(v);
                  },
                ),
                _ToggleTile(
                  icon: Icons.vibration,
                  label: lang.t('vibration'),
                  value: _vibration,
                  onChanged: (v) {
                    setState(() => _vibration = v);
                    _audio.setVibrationEnabled(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Reveal(
            delayMs: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(lang.t('about')),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline,
                            color: Color(0xFF6C63FF)),
                        title: Text(lang.t('app_name')),
                        subtitle: Text('${lang.t('version')}: 2.0.0'),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.person, color: Color(0xFF6C63FF)),
                        title: Text('Developer'),
                        subtitle: Text('Qurbonov M.'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.camera_alt,
                            color: Color(0xFFE1306C)),
                        title: const Text('Instagram'),
                        subtitle: const Text('@m_qurbonov10'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: _openInstagram,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final AppLanguage lang;
  const _LangTile({required this.lang});

  @override
  Widget build(BuildContext context) {
    const langs = [
      {'code': 'tj', 'label': '🇹🇯 Тоҷикӣ'},
      {'code': 'ru', 'label': '🇷🇺 Русский'},
      {'code': 'en', 'label': '🇬🇧 English'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: langs.map((l) {
          final selected = lang.lang == l['code'];
          return ListTile(
            title: Text(l['label']!),
            trailing: selected
                ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                : null,
            onTap: () => lang.setLanguage(l['code']!),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            selected: selected,
            selectedTileColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
          );
        }).toList(),
      ),
    );
  }
}
