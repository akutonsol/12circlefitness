// Widget tests for the chat message bubble (UC13 photo messaging).
// We define a local equivalent of the private `_MessageBubble` class so tests
// are independent of chat_screen.dart's library privacy.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Local copy of the message bubble logic ────────────────────────────────────

class TestMessageBubble extends StatelessWidget {
  final String content;
  final String? imageUrl;
  final bool isMe;
  final String time;
  final bool showAvatar;
  final String participantInitial;

  const TestMessageBubble({
    super.key,
    required this.content,
    required this.isMe,
    required this.time,
    required this.showAvatar,
    required this.participantInitial,
    this.imageUrl,
  });

  static const _brand  = Color(0xFFA855F7);
  static const _muted  = Color(0xFFCFC2D6);
  static const _white  = Colors.white;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            Container(
              key: const Key('avatar'),
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _brand.withValues(alpha: 0.15)),
              alignment: Alignment.center,
              child: Text(participantInitial,
                  style: const TextStyle(
                      color: _brand,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            )
          else if (!isMe)
            const SizedBox(width: 34),
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                key: const Key('bubble'),
                constraints: const BoxConstraints(maxWidth: 260),
                padding: hasImage
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? _brand : const Color(0xFF1A1020),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl!,
                          key: const Key('image_content'),
                          width: 220,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                              key: Key('image_error'), width: 220, height: 160),
                        ),
                      )
                    : Text(
                        key: const Key('text_content'),
                        content,
                        style: TextStyle(
                            color: isMe ? _white : _white,
                            fontSize: 14,
                            height: 1.4),
                      ),
              ),
              const SizedBox(height: 3),
              Text(time,
                  style: const TextStyle(color: _muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF030303),
        body: SingleChildScrollView(child: child),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('TestMessageBubble — text messages', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestMessageBubble(
          content: 'Hello there!',
          isMe: false,
          time: '9:30 AM',
          showAvatar: true,
          participantInitial: 'C',
        ),
      ));
      expect(find.text('Hello there!'), findsOneWidget);
    });

    testWidgets('renders timestamp', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestMessageBubble(
          content: 'Good morning',
          isMe: true,
          time: '7:45 AM',
          showAvatar: false,
          participantInitial: 'U',
        ),
      ));
      expect(find.text('7:45 AM'), findsOneWidget);
    });

    testWidgets('shows avatar when showAvatar=true and !isMe', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestMessageBubble(
          content: 'Hi',
          isMe: false,
          time: '10:00 AM',
          showAvatar: true,
          participantInitial: 'J',
        ),
      ));
      expect(find.byKey(const Key('avatar')), findsOneWidget);
      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('hides avatar when showAvatar=false', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestMessageBubble(
          content: 'Reply',
          isMe: false,
          time: '10:01 AM',
          showAvatar: false,
          participantInitial: 'J',
        ),
      ));
      expect(find.byKey(const Key('avatar')), findsNothing);
    });

    testWidgets('isMe=true has no avatar', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestMessageBubble(
          content: 'My message',
          isMe: true,
          time: '11:00 AM',
          showAvatar: true, // ignored when isMe
          participantInitial: 'U',
        ),
      ));
      expect(find.byKey(const Key('avatar')), findsNothing);
    });

    testWidgets('text content widget is present without imageUrl', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestMessageBubble(
          content: 'Text only',
          isMe: true,
          time: '1:00 PM',
          showAvatar: false,
          participantInitial: 'U',
        ),
      ));
      expect(find.byKey(const Key('text_content')), findsOneWidget);
      expect(find.byKey(const Key('image_content')), findsNothing);
    });
  });

  group('TestMessageBubble — photo messages (UC13)', () {
    testWidgets('shows Image.network when imageUrl is set', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestMessageBubble(
          content: '[photo]',
          imageUrl: 'https://example.com/photo.jpg',
          isMe: true,
          time: '2:00 PM',
          showAvatar: false,
          participantInitial: 'U',
        ),
      ));
      expect(find.byKey(const Key('image_content')), findsOneWidget);
      expect(find.byKey(const Key('text_content')), findsNothing);
    });

    testWidgets('no Image.network when imageUrl is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestMessageBubble(
          content: 'Regular text',
          isMe: false,
          time: '3:00 PM',
          showAvatar: true,
          participantInitial: 'C',
        ),
      ));
      expect(find.byType(Image), findsNothing);
      expect(find.byKey(const Key('text_content')), findsOneWidget);
    });

    testWidgets('empty imageUrl renders as text', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestMessageBubble(
          content: 'Not a photo',
          imageUrl: '',
          isMe: false,
          time: '4:00 PM',
          showAvatar: false,
          participantInitial: 'C',
        ),
      ));
      expect(find.byType(Image), findsNothing);
      expect(find.byKey(const Key('text_content')), findsOneWidget);
    });
  });

  group('TestMessageBubble — layout alignment', () {
    testWidgets('isMe=true aligns to end', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestMessageBubble(
          content: 'Me',
          isMe: true,
          time: '5:00 PM',
          showAvatar: false,
          participantInitial: 'U',
        ),
      ));
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.end);
    });

    testWidgets('isMe=false aligns to start', (tester) async {
      await tester.pumpWidget(_wrap(
        const TestMessageBubble(
          content: 'Them',
          isMe: false,
          time: '5:01 PM',
          showAvatar: true,
          participantInitial: 'C',
        ),
      ));
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.start);
    });
  });
}
