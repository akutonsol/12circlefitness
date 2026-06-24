import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_coach_service.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bg    = Color(0xFF030303);
const _card  = Color(0xFF0E0B16);
const _brd   = Color(0xFF1A1020);
const _brand = Color(0xFFA855F7);
const _pri   = Color(0xFFDDB7FF);
const _wht   = Colors.white;
const _mut   = Color(0xFFCFC2D6);
const _userBubble = Color(0xFF1A0F2E);

class _Message {
  final String text;
  final bool isUser;
  const _Message(this.text, {required this.isUser});
}

class AICoachScreen extends ConsumerStatefulWidget {
  const AICoachScreen({super.key});
  @override
  ConsumerState<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends ConsumerState<AICoachScreen> {
  final _svc = AICoachService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _messages = [];
  AICoachMode _mode = AICoachMode.general;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _svc.getConversationHistory(limit: 10);
    if (!mounted) return;
    setState(() {
      for (final h in history) {
        _messages.add(_Message(h['user_message'] as String, isUser: true));
        _messages.add(_Message(h['ai_response'] as String, isUser: false));
      }
    });
    if (_messages.isEmpty) {
      _addWelcome();
    }
    _scrollToBottom();
  }

  void _addWelcome() {
    _messages.add(const _Message(
      'Hey! I\'m your AI Coach. Ask me anything about nutrition, workouts, recovery, or your progress. What\'s on your mind? 💪',
      isUser: false,
    ));
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();
    setState(() {
      _messages.add(_Message(text, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _svc.chat(text, _mode);
      if (!mounted) return;
      setState(() => _messages.add(_Message(reply, isUser: false)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(_Message(
        'Sorry, I\'m having trouble connecting right now. Please try again in a moment.',
        isUser: false,
      )));
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _setMode(AICoachMode mode) {
    setState(() {
      _mode = mode;
      _messages.add(_Message(
        'Switched to ${mode.emoji} ${mode.label} mode. Ask me anything!',
        isUser: false,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _wht, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AI Coach', style: TextStyle(color: _wht, fontSize: 17, fontWeight: FontWeight.w700)),
          Text(_mode.emoji + ' ' + _mode.label,
            style: TextStyle(color: _brand, fontSize: 12)),
        ]),
        actions: [
          PopupMenuButton<AICoachMode>(
            color: _card,
            icon: const Icon(Icons.tune_rounded, color: _mut),
            onSelected: _setMode,
            itemBuilder: (_) => AICoachMode.values.map((m) => PopupMenuItem(
              value: m,
              child: Row(children: [
                Text(m.emoji),
                const SizedBox(width: 10),
                Text(m.label, style: const TextStyle(color: _wht)),
              ]),
            )).toList(),
          ),
        ],
      ),
      body: Column(children: [
        // ── Mode chips ───────────────────────────────────────────────────────
        Container(
          color: _card,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [AICoachMode.nutrition, AICoachMode.workout, AICoachMode.general]
                .map((m) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _setMode(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _mode == m ? _brand : _brd,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _mode == m ? _brand : _brd),
                      ),
                      child: Text('${m.emoji} ${m.label}',
                        style: TextStyle(color: _mode == m ? _wht : _mut, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                )).toList(),
            ),
          ),
        ),
        // ── Daily coaching insight ───────────────────────────────────────────
        if (_messages.length <= 1) const _DailyInsightCard(),
        // ── Suggested prompts ────────────────────────────────────────────────
        if (_messages.length <= 1)
          _SuggestedPrompts(mode: _mode, onTap: (p) { _ctrl.text = p; _send(); }),
        // ── Messages ─────────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _messages.length) return const _TypingIndicator();
              return _Bubble(msg: _messages[i]);
            },
          ),
        ),
        // ── Input ────────────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          decoration: const BoxDecoration(
            color: _card,
            border: Border(top: BorderSide(color: _brd)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: _wht, fontSize: 14),
                maxLines: 3, minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ask your AI coach...',
                  hintStyle: const TextStyle(color: _mut),
                  filled: true, fillColor: _bg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _brd)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _brd)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _brand)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _brand,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _brand.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)],
                ),
                child: const Icon(Icons.send_rounded, color: _wht, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Message msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFA855F7), Color(0xFF6FFBBE)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.auto_awesome, color: _wht, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? _userBubble : _card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(color: isUser ? _brand.withValues(alpha: 0.3) : _brd),
              ),
              child: Text(msg.text,
                style: TextStyle(
                  color: isUser ? _pri : _wht,
                  fontSize: 14, height: 1.5)),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFA855F7), Color(0xFF6FFBBE)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.auto_awesome, color: _wht, size: 16),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _brd)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('AI is thinking', style: TextStyle(color: _mut, fontSize: 13)),
          const SizedBox(width: 8),
          _DotLoader(),
        ]),
      ),
    ]),
  );
}

class _DotLoader extends StatefulWidget {
  @override
  State<_DotLoader> createState() => _DotLoaderState();
}
class _DotLoaderState extends State<_DotLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
      final delay = i * 0.33;
      final t = (_ctrl.value - delay).clamp(0.0, 1.0);
      final opacity = (t < 0.5 ? t * 2 : (1.0 - t) * 2).clamp(0.3, 1.0);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Opacity(
          opacity: opacity,
          child: const CircleAvatar(radius: 3, backgroundColor: _brand),
        ),
      );
    })),
  );
}

class _SuggestedPrompts extends StatelessWidget {
  final AICoachMode mode;
  final void Function(String) onTap;
  const _SuggestedPrompts({required this.mode, required this.onTap});

  static const _prompts = {
    AICoachMode.nutrition: [
      'What should I eat after my workout?',
      'I\'m craving something sweet — what fits my macros?',
      'How do I hit my protein goal today?',
    ],
    AICoachMode.workout: [
      'How do I do a Romanian Deadlift correctly?',
      'What can I substitute for pull-ups?',
      'Why are my shoulders not growing?',
    ],
    AICoachMode.general: [
      'How do I break through a plateau?',
      'Should I take rest days?',
      'How do I stay motivated?',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final suggestions = _prompts[mode] ?? _prompts[AICoachMode.general]!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: suggestions.map((p) => GestureDetector(
          onTap: () => onTap(p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _brd)),
            child: Text(p, style: const TextStyle(color: _pri, fontSize: 12)),
          ),
        )).toList(),
      ),
    );
  }
}

// ── Daily coaching insight card ───────────────────────────────────────────────
class _DailyInsightCard extends StatefulWidget {
  const _DailyInsightCard();
  @override
  State<_DailyInsightCard> createState() => _DailyInsightCardState();
}

class _DailyInsightCardState extends State<_DailyInsightCard> {
  final _svc = AICoachService();
  Map<String, dynamic>? _insight;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = await _svc.getTodayInsight();
    if (!mounted) return;
    setState(() { _insight = today; _loading = false; });
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    final res = await _svc.generate('daily_insight');
    if (!mounted) return;
    if (res != null) {
      // Shape the engine result like a stored row for display.
      setState(() {
        _insight = {
          'title': res['title'], 'body': res['body'],
          'data': {
            'focus': res['focus'], 'intensity_delta': res['intensity_delta'],
            'nutrition_note': res['nutrition_note'], 'recovery_note': res['recovery_note'],
          },
        };
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate your brief. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = (_insight?['data'] as Map?) ?? const {};
    final delta = (data['intensity_delta'] as num?)?.round() ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0F2E), Color(0xFF0E0B16)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brand.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_awesome_rounded, color: _pri, size: 18),
          const SizedBox(width: 8),
          const Text("TODAY'S COACHING BRIEF",
            style: TextStyle(color: _pri, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const Spacer(),
          if (_loading)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _pri)),
        ]),
        const SizedBox(height: 12),
        if (_insight == null && !_loading) ...[
          const Text('Get a personalized brief from your data — recovery, adherence, and goals.',
            style: TextStyle(color: _mut, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _generate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _brand, borderRadius: BorderRadius.circular(12)),
              child: const Text('Generate Today’s Brief',
                style: TextStyle(color: _wht, fontSize: 13, fontWeight: FontWeight.w700))),
          ),
        ] else if (_insight != null) ...[
          Text(_insight!['title']?.toString() ?? 'Today’s Coaching',
            style: const TextStyle(color: _wht, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(_insight!['body']?.toString() ?? '',
            style: const TextStyle(color: _mut, fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (data['focus'] != null)
              _chip(Icons.center_focus_strong_rounded, _humanize(data['focus'].toString())),
            if (delta != 0)
              _chip(delta < 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                'Intensity ${delta > 0 ? '+' : ''}$delta%',
                color: delta < 0 ? const Color(0xFFF59E0B) : _C2.green),
          ]),
          if (data['nutrition_note'] != null) _noteRow(Icons.restaurant_rounded, data['nutrition_note'].toString()),
          if (data['recovery_note'] != null) _noteRow(Icons.self_improvement_rounded, data['recovery_note'].toString()),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _generate,
            child: const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('↻ Refresh brief', style: TextStyle(color: _pri, fontSize: 12, fontWeight: FontWeight.w600))),
          ),
        ],
      ]),
    );
  }

  Widget _chip(IconData icon, String label, {Color color = _pri}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.35))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 13), const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]));

  Widget _noteRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: _mut, size: 15), const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: _mut, fontSize: 12, height: 1.4))),
    ]));

  String _humanize(String s) => s.split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class _C2 { static const green = Color(0xFF6FFBBE); }
