import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/messaging_service.dart';

final messagingServiceProvider = Provider<MessagingService>((ref) => MessagingService());

final conversationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(messagingServiceProvider).getConversations();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(messagingServiceProvider).getUnreadCount();
});

// Holds the currently selected conversation context for ChatScreen.
// Set before navigating to /chat so the screen knows who it's talking to.
final selectedConversationProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
