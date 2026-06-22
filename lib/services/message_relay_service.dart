import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'message_storage_service.dart';

class MessageRelayService {
  static const _relayTable = 'message_relay';
  final MessageStorageService _storage;
  RealtimeChannel? _channel;

  final ValueNotifier<int> messageNotifier = ValueNotifier(0);

  MessageRelayService(this._storage);

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  Future<void> sendMessage({
    required String receiverId,
    required String text,
  }) async {
    final messageId = const Uuid().v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final senderId = _userId;

    final msg = LocalMessage(
      id: messageId,
      conversationId: receiverId,
      text: text,
      senderId: senderId,
      timestamp: timestamp,
      status: 'sent',
    );

    await _storage.insertMessage(msg);

    try {
      await Supabase.instance.client.from(_relayTable).insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'text': text,
      });
      await _storage.markAsDelivered(messageId);
      messageNotifier.value++;
    } catch (_) {}
  }

  Future<void> syncMissedMessages() async {
    final userId = _userId;
    if (userId.isEmpty) return;

    try {
      final response = await Supabase.instance.client
          .from(_relayTable)
          .select()
          .eq('receiver_id', userId)
          .order('created_at', ascending: true);

      for (final data in response) {
        final msg = LocalMessage(
          id: data['id'] as String,
          conversationId: data['sender_id'] as String,
          text: data['text'] as String,
          senderId: data['sender_id'] as String,
          timestamp: DateTime.parse(data['created_at'] as String)
              .millisecondsSinceEpoch,
          status: 'received',
        );

        await _storage.insertMessage(msg);
        messageNotifier.value++;

        try {
          await Supabase.instance.client
              .from(_relayTable)
              .delete()
              .eq('id', data['id'] as String);
        } catch (_) {}
      }
    } catch (_) {}
  }

  void subscribeToIncoming() {
    _channel?.unsubscribe();
    final userId = _userId;
    if (userId.isEmpty) return;

    _channel = Supabase.instance.client
        .channel('message_relay_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: _relayTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) async {
            final data = payload.newRecord;

            final msg = LocalMessage(
              id: data['id'] as String,
              conversationId: data['sender_id'] as String,
              text: data['text'] as String,
              senderId: data['sender_id'] as String,
              timestamp: DateTime.parse(data['created_at'] as String)
                  .millisecondsSinceEpoch,
              status: 'received',
            );

            await _storage.insertMessage(msg);

            messageNotifier.value++;

            try {
              await Supabase.instance.client
                  .from(_relayTable)
                  .delete()
                  .eq('id', data['id'] as String);
            } catch (_) {}
          },
        )
        .subscribe();

    syncMissedMessages();
  }

  void unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
  }

  void dispose() {
    unsubscribe();
  }
}
