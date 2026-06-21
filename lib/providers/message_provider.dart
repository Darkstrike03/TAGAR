import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/message_storage_service.dart';
import '../services/message_relay_service.dart';

final messageStorageProvider = Provider<MessageStorageService>((ref) {
  final svc = MessageStorageService();
  ref.onDispose(() => svc.close());
  return svc;
});

final messageRelayProvider = Provider<MessageRelayService>((ref) {
  final storage = ref.read(messageStorageProvider);
  final svc = MessageRelayService(storage);
  ref.onDispose(() => svc.dispose());
  return svc;
});

final conversationsProvider = FutureProvider<List<ConversationSummary>>((ref) {
  final storage = ref.read(messageStorageProvider);
  return storage.getConversations();
});

final messagesForConversationProvider =
    FutureProvider.family<List<LocalMessage>, String>((ref, conversationId) {
  final storage = ref.read(messageStorageProvider);
  return storage.getMessages(conversationId);
});

final unreadCountProvider =
    FutureProvider.family<int, String>((ref, conversationId) {
  final storage = ref.read(messageStorageProvider);
  return storage.getUnreadCount(conversationId);
});
