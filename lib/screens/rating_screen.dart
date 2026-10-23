import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/helpers.dart';
import '../widgets/quiz_widgets.dart';
import '../widgets/reveal.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final _db = FirestoreService();
  final _auth = AuthService();
  bool _byWins = false;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final field = _byWins ? 'gamesWon' : 'totalScore';

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('global_rating'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SelectChip(
                  label: '⭐ ${lang.t('points')}',
                  selected: !_byWins,
                  onTap: () => setState(() => _byWins = false),
                ),
                const SizedBox(width: 10),
                SelectChip(
                  label: '🏆 ${lang.t('wins')}',
                  selected: _byWins,
                  onTap: () => setState(() => _byWins = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(field),
              stream: _db.streamTopPlayers(orderBy: field),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text(lang.t('error')));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Бозингарони бе ном дар рӯйхат нишон дода намешаванд
                final rows = snap.data!.docs
                    .map((d) => d.data())
                    .where((d) => (d['name'] as String? ?? '').trim().isNotEmpty)
                    .toList();
                if (rows.isEmpty) {
                  return Center(child: Text(lang.t('no_players')));
                }

                final showPodium = rows.length >= 3;
                final listStart = showPodium ? 3 : 0;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  children: [
                    if (showPodium) _Podium(rows: rows, byWins: _byWins),
                    const SizedBox(height: 8),
                    for (int i = listStart; i < rows.length; i++)
                      Reveal(
                        delayMs: (i - listStart) < 8 ? (i - listStart) * 60 : 0,
                        dy: 10,
                        child: _RatingRow(
                          rank: i + 1,
                          data: rows[i],
                          isMe: rows[i]['uid'] == _auth.uid,
                          byWins: _byWins,
                          lang: lang,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> data;
  final bool isMe;
  final bool byWins;
  final AppLanguage lang;

  const _RatingRow({
    required this.rank,
    required this.data,
    required this.isMe,
    required this.byWins,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = (data['totalScore'] as num?)?.toInt() ?? 0;
    final wins = (data['gamesWon'] as num?)?.toInt() ?? 0;
    final level = AppHelpers.levelFor(score);
    final name = data['name'] as String? ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? theme.primaryColor.withValues(alpha: 0.15)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isMe
            ? Border.all(color: theme.primaryColor.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text('$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500)),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppHelpers.avatarColor(name),
            child: Text(AppHelpers.initial(name),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: isMe ? FontWeight.w800 : FontWeight.w600)),
                Text('${lang.t('level')} $level',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(byWins ? '🏆 $wins' : '⭐ $score',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(byWins ? '⭐ $score' : '🏆 $wins',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final bool byWins;
  const _Podium({required this.rows, required this.byWins});

  @override
  Widget build(BuildContext context) {
    const heights = [96.0, 74.0, 58.0];
    const order = [1, 0, 2];
    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final i in order)
            Expanded(
              child: Reveal(
                delayMs: 100 + (2 - i) * 160,
                child: _Column(
                  rank: i + 1,
                  name: (rows[i]['name'] as String? ?? '—'),
                  value: byWins
                      ? (rows[i]['gamesWon'] as num?)?.toInt() ?? 0
                      : (rows[i]['totalScore'] as num?)?.toInt() ?? 0,
                  height: heights[i],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final int rank;
  final String name;
  final int value;
  final double height;
  const _Column(
      {required this.rank,
      required this.name,
      required this.value,
      required this.height});

  @override
  Widget build(BuildContext context) {
    final color = AppHelpers.getRankColor(rank);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(AppHelpers.getRankEmoji(rank), style: const TextStyle(fontSize: 26)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.18)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color.withValues(alpha: 0.7)),
          ),
          child: Center(
            child: Text('$value',
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: color, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}
