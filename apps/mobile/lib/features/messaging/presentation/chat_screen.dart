import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/messaging_service.dart';
import '../domain/messaging_provider.dart';
import '../../scoring/data/score_engine.dart';

const _bg      = Color(0xFF030303);
const _card    = Color(0xFF0E0B16);
const _border  = Color(0xFF1A1020);
const _brand  = Color(0xFFA855F7);
const _white  = Colors.white;
const _muted  = Color(0xFFCFC2D6);
const _green  = Color(0xFF22C55E);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _service    = MessagingService();
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();

  String? _conversationId;
  String  _participantName = 'Coach';
  List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _sub;
  bool _sending  = false;
  bool _hasText  = false;
  bool _loading  = true;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() =>
      setState(() => _hasText = _msgCtrl.text.trim().isNotEmpty));
    // Defer so we can safely read providers
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Read the conversation context set by the caller before navigating here
    final conv = ref.read(selectedConversationProvider);

    String? convId = conv?['id'] as String?;
    final participant = conv?['participant'] as Map<String, dynamic>?;
    final fn = participant?['first_name'] as String? ?? '';
    final ln = participant?['last_name'] as String? ?? '';
    final name = '$fn $ln'.trim();

    if (mounted) {
      setState(() => _participantName = name.isNotEmpty ? name : 'Coach');
    }

    // If no conversation was pre-selected, find/create one. Prefer the exact
    // participant the caller passed (e.g. the assigned coach), else fall back to
    // the client's active coach.
    if (convId == null) {
      final pid = participant?['id'] as String?;
      convId = (pid != null && pid.isNotEmpty)
          ? await _service.getOrCreateConversationWith(pid)
          : await _service.getOrCreateClientCoachConversation();
    }

    if (convId != null && mounted) {
      setState(() => _conversationId = convId);
      final msgs = await _service.getMessages(convId);
      if (mounted) {
        setState(() {
          _messages = msgs.isNotEmpty ? msgs : _service.getSampleMessages();
          _loading = false;
        });
      }
      await _service.markAsRead(convId);
      _sub = _service.messagesStream(convId).listen((msgs) {
        if (mounted) setState(() => _messages = msgs);
        _scrollToBottom();
      });
    } else if (mounted) {
      setState(() {
        _messages = _service.getSampleMessages();
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() => _hasText = false);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'me';
    // Optimistic update
    final optimistic = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender_id': userId,
      'content': text,
      'sent_at': DateTime.now().toIso8601String(),
      'is_read': false,
    };
    setState(() => _messages = [..._messages, optimistic]);
    _scrollToBottom();
    if (_conversationId != null) {
      await _service.sendMessage(conversationId: _conversationId!, content: text);
      ScoreEngine().messageCoach(); // +5, once/day (server dedup)
    }
  }

  Future<void> _sendPhoto() async {
    if (_conversationId == null || _sending) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _sending = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id ?? 'me';
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'messages/$uid/${ts}.$ext';
      await Supabase.instance.client.storage
          .from('chat-media')
          .uploadBinary(storagePath, bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: false));
      final publicUrl = Supabase.instance.client.storage
          .from('chat-media')
          .getPublicUrl(storagePath);
      await _service.sendMessage(
        conversationId: _conversationId!,
        content: '[photo]',
        metadata: {'image_url': publicUrl});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send photo'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _isMe(Map<String, dynamic> msg) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return msg['sender_id'] == userId || msg['sender_id'] == 'me';
  }

  String _formatTime(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    final h  = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m  = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(child: Column(children: [

        // ── Header ──
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          decoration: const BoxDecoration(
            color: _card,
            border: Border(bottom: BorderSide(color: _border))),
          child: Row(children: [
            GestureDetector(
              onTap: () => context.go('/messages'),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: _white, size: 18))),
            const SizedBox(width: 10),
            // Avatar
            Stack(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _brand.withValues(alpha: 0.15),
                  border: Border.all(color: _brand.withValues(alpha: 0.4), width: 1.5)),
                alignment: Alignment.center,
                child: Text(
                  _participantName.isNotEmpty ? _participantName[0].toUpperCase() : '?',
                  style: const TextStyle(color: _brand, fontSize: 16, fontWeight: FontWeight.w800))),
              Positioned(bottom: 0, right: 0,
                child: Container(
                  width: 11, height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _green,
                    border: Border.all(color: _card, width: 1.5)))),
            ]),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_participantName,
                  style: const TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700)),
                const Text("Online now",
                  style: TextStyle(color: _green, fontSize: 11)),
              ])),
          ])),

        // ── Messages ──
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: _brand))
            : _messages.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline, color: _brand.withValues(alpha: 0.3), size: 48),
                  const SizedBox(height: 12),
                  Text("Start the conversation!",
                    style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 14)),
                ]))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg   = _messages[i];
                    final isMe  = _isMe(msg);
                    final showAvatar = !isMe && (i == 0 || _isMe(_messages[i - 1]));
                    final meta = msg['metadata'] as Map<String, dynamic>?;
                    return _MessageBubble(
                      content: msg['content'] ?? '',
                      imageUrl: meta?['image_url'] as String?,
                      isMe: isMe,
                      time: _formatTime(msg['sent_at'] ?? DateTime.now().toIso8601String()),
                      showAvatar: showAvatar,
                      participantInitial: _participantName.isNotEmpty
                        ? _participantName[0].toUpperCase() : '?');
                  })),

        // ── Input bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: _card,
            border: Border(top: BorderSide(color: _border))),
          child: Row(children: [
            // Photo attachment button
            GestureDetector(
              onTap: _sendPhoto,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06)),
                child: const Icon(Icons.image_outlined, color: _muted, size: 20))),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border)),
                child: TextField(
                  controller: _msgCtrl,
                  style: const TextStyle(color: _white, fontSize: 14),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Message $_participantName...',
                    hintStyle: TextStyle(color: _muted.withValues(alpha: 0.35), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                  onTapOutside: (_) => FocusScope.of(context).unfocus()))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hasText ? _brand : _border,
                  boxShadow: _hasText
                    ? [BoxShadow(color: _brand.withValues(alpha: 0.4), blurRadius: 12)]
                    : null),
                child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: _white, size: 20))),
          ])),

      ])));
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String content, time;
  final String? imageUrl;
  final String participantInitial;
  final bool isMe, showAvatar;
  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.time,
    required this.showAvatar,
    required this.participantInitial,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showAvatar)
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _brand.withValues(alpha: 0.15),
                  border: Border.all(color: _brand.withValues(alpha: 0.3))),
                alignment: Alignment.center,
                child: Text(participantInitial,
                  style: const TextStyle(color: _brand, fontSize: 12, fontWeight: FontWeight.w800)))
            else
              const SizedBox(width: 30),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.70),
                  decoration: BoxDecoration(
                    color: isMe ? _brand : _card,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18)),
                    border: isMe ? null : Border.all(color: _border),
                    boxShadow: isMe
                      ? [BoxShadow(color: _brand.withValues(alpha: 0.25), blurRadius: 8)]
                      : null),
                  child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(imageUrl!,
                          width: MediaQuery.of(context).size.width * 0.60,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const SizedBox(height: 120,
                                child: Center(child: CircularProgressIndicator(
                                  color: _brand, strokeWidth: 2))),
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined, color: _muted, size: 40)))
                    : Text(content,
                        style: const TextStyle(color: _white, fontSize: 14, height: 1.4))),
                const SizedBox(height: 3),
                Text(time,
                  style: TextStyle(color: _muted.withValues(alpha: 0.4), fontSize: 10)),
              ])),
          if (isMe) const SizedBox(width: 4),
        ]));
  }
}
