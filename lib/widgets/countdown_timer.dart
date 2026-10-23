import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Идоракунии таймер аз берун: вақт илова кардан, таваққуф, хондани вақти боқимонда
class CountdownController {
  _CountdownTimerState? _state;

  void addSeconds(int s) => _state?._addSeconds(s);
  void pause() => _state?._pause();
  void resume() => _state?._resume();
  int get remainingMs => _state?._remainingMs ?? 0;
  int get remainingSeconds => (remainingMs / 1000).ceil();
}

/// Таймер дар асоси Ticker (соати дақиқ), на Timer.periodic.
/// Вақт аз рӯи соат ҳисоб мешавад, бинобар ин "давидан" ё "суст шудан" нест.
class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onFinished;
  final ValueChanged<int>? onTick;
  final CountdownController? controller;
  final double size;

  const CountdownTimer({
    super.key,
    required this.seconds,
    required this.onFinished,
    this.onTick,
    this.controller,
    this.size = 68,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late int _totalMs;
  int _baseMs = 0; // вақти гузашта пеш аз таваққуфи охирин
  int _runMs = 0; // вақти гузашта дар давраи ҷорӣ
  bool _finished = false;
  bool _paused = false;
  int _lastSec = -1;

  int get _elapsed => _baseMs + _runMs;
  int get _remainingMs => max(0, _totalMs - _elapsed);

  @override
  void initState() {
    super.initState();
    _totalMs = widget.seconds * 1000;
    _lastSec = widget.seconds;
    widget.controller?._state = this;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(CountdownTimer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (old.controller?._state == this) old.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  void _onTick(Duration d) {
    if (_finished) return;
    _runMs = d.inMilliseconds;
    final sec = (_remainingMs / 1000).ceil();
    if (sec != _lastSec) {
      _lastSec = sec;
      widget.onTick?.call(sec);
    }
    if (_remainingMs <= 0) {
      _finished = true;
      _ticker.stop();
      if (mounted) setState(() {});
      widget.onFinished();
      return;
    }
    if (mounted) setState(() {});
  }

  void _pause() {
    if (_paused || _finished) return;
    _paused = true;
    _baseMs += _runMs;
    _runMs = 0;
    _ticker.stop();
    if (mounted) setState(() {});
  }

  void _resume() {
    if (!_paused || _finished) return;
    _paused = false;
    if (!_ticker.isActive) _ticker.start();
  }

  void _addSeconds(int s) {
    if (_finished) return;
    _totalMs += s * 1000;
    _lastSec = (_remainingMs / 1000).ceil();
    widget.onTick?.call(_lastSec);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _ticker.dispose();
    super.dispose();
  }

  Color get _color {
    final ratio = _remainingMs / _totalMs;
    if (ratio > 0.5) return const Color(0xFF22C55E);
    if (ratio > 0.25) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final sec = (_remainingMs / 1000).ceil();
    final frac = (_remainingMs % 1000) / 1000.0;
    final urgent = sec <= 5 && !_paused && !_finished;
    final scale = urgent ? 1 + 0.16 * frac : 1.0;
    final color = _color;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: _remainingMs / _totalMs,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: color.withValues(alpha: 0.18),
            ),
          ),
          Transform.scale(
            scale: scale,
            child: Text(
              '$sec',
              style: TextStyle(
                fontSize: widget.size * 0.36,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
