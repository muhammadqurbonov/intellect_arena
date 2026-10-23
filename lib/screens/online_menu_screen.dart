import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../services/firestore_service.dart';
import '../utils/app_route.dart';
import '../widgets/animated_background.dart';
import '../widgets/app_button.dart';
import '../widgets/name_gate.dart';
import '../widgets/reveal.dart';
import 'create_room_screen.dart';
import 'waiting_room_screen.dart';

class OnlineMenuScreen extends StatefulWidget {
  const OnlineMenuScreen({super.key});
  @override
  State<OnlineMenuScreen> createState() => _OnlineMenuScreenState();
}

class _OnlineMenuScreenState extends State<OnlineMenuScreen> {
  final _codeCtrl = TextEditingController();
  final _db = FirestoreService();
  bool _joining = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    final text = (data?.text ?? '').trim().toUpperCase();
    if (text.isNotEmpty) {
      _codeCtrl.text = text.length > 6 ? text.substring(0, 6) : text;
      setState(() {});
    }
  }

  Future<void> _joinRoom() async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      _snack(lang.t('code_6'));
      return;
    }

    final hasName = await NameGate.check(context);
    if (!hasName || !mounted) return;

    setState(() => _joining = true);
    try {
      final room = await _db.findRoomByCode(code);
      if (room == null) {
        _snack(lang.t('room_not_found'));
        return;
      }
      if (room['status'] != 'waiting') {
        _snack(lang.t('room_already_started'));
        return;
      }
      final err = await _db.joinRoom(room['id'] as String);
      if (err != null) {
        _snack(lang.t(err));
        return;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        appRoute(WaitingRoomScreen(roomId: room['id'] as String, isHost: false)),
      );
    } catch (e) {
      _snack('${lang.t('error')}: $e');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _goCreate() async {
    final hasName = await NameGate.check(context);
    if (!hasName || !mounted) return;
    Navigator.push(context, appRoute(const CreateRoomScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(lang.t('play_online'))),
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
            child: Column(
              children: [
                Reveal(
                  child: _BigCard(
                    emoji: '🎮',
                    title: lang.t('create_room'),
                    subtitle: lang.t('create_room_d'),
                    color: const Color(0xFF6C63FF),
                    onTap: _goCreate,
                  ),
                ),
                const SizedBox(height: 24),
                Reveal(
                  delayMs: 120,
                  child: Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(lang.t('or'),
                          style: const TextStyle(color: Colors.grey)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                ),
                const SizedBox(height: 24),
                Reveal(
                  delayMs: 220,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        Text(lang.t('join_room'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8),
                          decoration: InputDecoration(
                            hintText: 'XXXXXX',
                            counterText: '',
                            suffixIcon: IconButton(
                              tooltip: lang.t('paste'),
                              icon: const Icon(Icons.content_paste_rounded),
                              onPressed: _paste,
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          text: lang.t('join'),
                          loading: _joining,
                          onTap: _joinRoom,
                          icon: Icons.login_rounded,
                          color: const Color(0xFF03B5A8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BigCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 42)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}
