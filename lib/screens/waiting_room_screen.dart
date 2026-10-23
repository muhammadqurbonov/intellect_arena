import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../models/question_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_route.dart';
import '../utils/constants.dart';
import '../widgets/animated_background.dart';
import '../widgets/app_button.dart';
import '../widgets/player_tile.dart';
import '../widgets/reveal.dart';
import 'online_game_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String roomId;
  final bool isHost;

  const WaitingRoomScreen({super.key, required this.roomId, required this.isHost});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final _auth = AuthService();
  final _db = FirestoreService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  Map<String, dynamic>? _data;
  bool _started = false; // ба бозӣ гузаштем: аз ҳуҷра набаромадан!
  bool _left = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _sub = _db.streamRoom(widget.roomId).listen(_onRoom, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    // Танҳо агар бозӣ оғоз нашуда бошад, аз ҳуҷра мебароем
    if (!_started && !_left) _db.leaveRoom(widget.roomId);
    super.dispose();
  }

  void _onRoom(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!mounted || _started || _left) return;
    final data = snap.data();

    // Ҳуҷра нест шуд (мизбон баромад)
    if (!snap.exists || data == null) {
      _left = true;
      final lang = Provider.of<AppLanguage>(context, listen: false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(lang.t('room_closed'))));
      Navigator.of(context).pop();
      return;
    }

    if (data['status'] == 'playing') {
      _started = true;
      Navigator.pushReplacement(
        context,
        appRoute(OnlineGameScreen(
          roomId: widget.roomId,
          isHost: widget.isHost,
          roomData: data,
        )),
      );
      return;
    }
    setState(() => _data = data);
  }

  Future<void> _leave() async {
    if (_left) return;
    _left = true;
    await _db.leaveRoom(widget.roomId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _startGame() async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    final players = (_data?['players'] as Map?) ?? {};
    if (players.length < 2) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(lang.t('min_players'))));
      return;
    }
    setState(() => _starting = true);
    try {
      await _db.startGame(widget.roomId);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final data = _data;

    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final code = data['code'] as String? ?? '';
    final playersMap = Map<String, dynamic>.from(data['players'] ?? {});
    final players = playersMap.values
        .map((p) => PlayerModel.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList()
      ..sort((a, b) => (b.isHost ? 1 : 0) - (a.isHost ? 1 : 0));
    final qCount = (data['questionCount'] as num?)?.toInt() ??
        (data['questions'] as List? ?? []).length;
    final time = (data['timePerQuestion'] as num?)?.toInt() ?? 20;
    final category = data['category'] as String? ?? 'all';
    final canStart = players.length >= 2;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(lang.t('waiting_for_players')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _leave,
          ),
        ),
        body: AnimatedBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
              child: Column(
                children: [
                  Reveal(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: AppColors.brand,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(lang.t('room_code'),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(
                            code,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(lang.t('code_copied'))),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded,
                                color: Colors.white, size: 18),
                            label: Text(lang.t('copy_code'),
                                style: const TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: [
                              _InfoPill('❓ $qCount'),
                              _InfoPill('⏱️ $time ${lang.t('sec_short')}'),
                              _InfoPill('🗂️ ${lang.t('cat_$category')}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('${lang.t('players')} (${players.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (_, i) => Reveal(
                        key: ValueKey(players[i].uid),
                        dy: 12,
                        child: PlayerTile(
                          player: players[i],
                          rank: i + 1,
                          isMe: players[i].uid == _auth.uid,
                        ),
                      ),
                    ),
                  ),
                  if (widget.isHost)
                    AppButton(
                      text: canStart
                          ? lang.t('start_game')
                          : lang.t('min_players'),
                      loading: _starting,
                      onTap: canStart ? _startGame : null,
                      icon: Icons.play_arrow_rounded,
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(lang.t('waiting_host')),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  const _InfoPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
