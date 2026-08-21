// Coach Audio Coaching — Exercise Audio. A coach holds to record a short voice
// note on an exercise; every client performing it hears their coach. Recording
// is deliberately low-friction (hold → release → send, 30s cap, no trimming/
// naming). Playback is one tap with a lightweight waveform. Cached by the player.
//
// NOTE: audio capture/playback is device/browser-specific and cannot be verified
// headlessly — this needs on-device testing (mic permission + capture + upload +
// playback across web/iOS/Android). Structured against record ^7 / audioplayers ^6.
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../data/custom_exercise_service.dart';

const _brand = Color(0xFFB76DFF);
const _mint  = Color(0xFFFF6B6B);
const _text  = Color(0xFFEDE7F3);
const _muted = Color(0xFFB6A9C4);
const _panel = Color(0xFF1B1526);

const _maxSeconds = 30;

// Fixed decorative bar heights — a waveform that "feels alive" without sampling
// the audio (transcription/analysis is intentionally out of scope for beta).
const _bars = [0.3, 0.6, 0.9, 0.5, 0.8, 1.0, 0.4, 0.7, 0.55, 0.85, 0.35, 0.65,
  0.95, 0.5, 0.75, 0.45, 0.9, 0.6, 0.3, 0.8, 0.5, 0.7, 0.4, 0.6];

// ── Recorder: hold to record, release to send ───────────────────────────────
class CoachVoiceRecorder extends StatefulWidget {
  final String exerciseId;
  final DateTime? Function() resolveExpiry;
  final VoidCallback onRecorded;
  const CoachVoiceRecorder({super.key,
    required this.exerciseId, required this.resolveExpiry, required this.onRecorded});
  @override
  State<CoachVoiceRecorder> createState() => _CoachVoiceRecorderState();
}

class _CoachVoiceRecorderState extends State<CoachVoiceRecorder> {
  final _rec = AudioRecorder();
  final _svc = CustomExerciseService();
  bool _recording = false, _busy = false;
  int _elapsed = 0;
  Timer? _timer;
  DateTime? _startedAt;

  @override
  void dispose() { _timer?.cancel(); _rec.dispose(); super.dispose(); }

  Future<void> _start() async {
    if (_busy || _recording) return;
    try {
      if (!await _rec.hasPermission()) return;
      final String path;
      if (kIsWeb) {
        path = 'coach-voice.m4a';
      } else {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/coach-voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
      }
      await _rec.start(const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1), path: path);
      _startedAt = DateTime.now();
      setState(() { _recording = true; _elapsed = 0; });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => _elapsed++);
        if (_elapsed >= _maxSeconds) _stop();
      });
    } catch (_) { setState(() => _recording = false); }
  }

  Future<void> _stop() async {
    if (!_recording) return;
    _timer?.cancel();
    setState(() { _recording = false; _busy = true; });
    try {
      final path = await _rec.stop();
      final durationMs = _startedAt == null ? 0 : DateTime.now().difference(_startedAt!).inMilliseconds;
      if (path == null || durationMs < 800) { setState(() => _busy = false); return; } // discard taps
      final bytes = await XFile(path).readAsBytes();
      final url = await _svc.uploadCoachVoice(widget.exerciseId, bytes);
      if (url != null) {
        await _svc.setCoachVoice(widget.exerciseId, url, durationMs, widget.resolveExpiry());
        widget.onRecorded();
      }
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _start(),
      onLongPressEnd: (_) => _stop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _recording ? _mint.withValues(alpha: 0.18) : _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (_recording ? _mint : _brand).withValues(alpha: 0.4))),
        child: Row(children: [
          if (_busy)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _brand, strokeWidth: 2))
          else
            Icon(_recording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                color: _recording ? _mint : _brand, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(
            _busy ? 'Sending…'
                  : _recording ? 'Recording… ${_elapsed}s  (release to send)'
                               : 'Hold to record a voice note',
            style: TextStyle(color: _recording ? _mint : _text, fontSize: 13.5, fontWeight: FontWeight.w600))),
          if (_recording) Text('${_maxSeconds - _elapsed}s',
              style: const TextStyle(color: _muted, fontSize: 11)),
        ]),
      ),
    );
  }
}

// ── Player: one tap, waveform fills with progress ───────────────────────────
class CoachVoicePlayer extends StatefulWidget {
  final String url;
  final int? durationMs;
  final String? coachName;
  const CoachVoicePlayer({super.key, required this.url, this.durationMs, this.coachName});
  @override
  State<CoachVoicePlayer> createState() => _CoachVoicePlayerState();
}

class _CoachVoicePlayerState extends State<CoachVoicePlayer> {
  final _player = AudioPlayer();
  bool _playing = false;
  double _progress = 0; // 0..1
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.durationMs != null) _total = Duration(milliseconds: widget.durationMs!);
    _player.onDurationChanged.listen((d) { if (mounted && d > Duration.zero) setState(() => _total = d); });
    _player.onPositionChanged.listen((p) {
      if (!mounted || _total == Duration.zero) return;
      setState(() => _progress = (p.inMilliseconds / _total.inMilliseconds).clamp(0, 1));
    });
    _player.onPlayerComplete.listen((_) { if (mounted) setState(() { _playing = false; _progress = 0; }); });
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  Future<void> _toggle() async {
    if (_playing) { await _player.pause(); setState(() => _playing = false); return; }
    try {
      if (_progress == 0) {
        await _player.play(UrlSource(widget.url));
      } else {
        await _player.resume();
      }
      setState(() => _playing = true);
    } catch (_) {}
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _brand.withValues(alpha: 0.3))),
        child: Row(children: [
          Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: _brand, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.coachName != null ? 'Listen to ${widget.coachName}' : 'Coach voice note',
                style: const TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SizedBox(height: 20, child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [for (var i = 0; i < _bars.length; i++)
                Expanded(child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: 4 + _bars[i] * 16,
                  decoration: BoxDecoration(
                    color: (i / _bars.length) <= _progress ? _brand : _brand.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2)),
                ))],
            )),
          ])),
          const SizedBox(width: 8),
          Text(_fmt(_total), style: const TextStyle(color: _muted, fontSize: 11)),
        ]),
      ),
    );
  }
}
