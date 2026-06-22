import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceService {
  RealtimeChannel? _myChannel;
  final Map<String, RealtimeChannel> _watchedChannels = {};
  bool _isTracking = false;

  final ValueNotifier<Map<String, bool>> contactStatus = ValueNotifier({});

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  static String _channelName(String userId) => 'presence:$userId';

  Future<void> track() async {
    if (_isTracking) return;
    _isTracking = true;

    final userId = _userId;
    if (userId == null) return;

    _myChannel = Supabase.instance.client.channel(_channelName(userId));
    _myChannel!.subscribe();
    _myChannel!.track({'user_id': userId});
  }

  void watch(String userId) {
    if (_watchedChannels.containsKey(userId)) return;

    final channel = Supabase.instance.client.channel(_channelName(userId));
    channel.onPresenceSync((_) {
      final isOnline = channel.presenceState().isNotEmpty;
      final updated = Map<String, bool>.from(contactStatus.value);
      if (isOnline) {
        updated[userId] = true;
      } else {
        updated.remove(userId);
      }
      contactStatus.value = updated;
    }).subscribe();

    if (channel.presenceState().isNotEmpty) {
      final updated = Map<String, bool>.from(contactStatus.value);
      updated[userId] = true;
      contactStatus.value = updated;
    }

    _watchedChannels[userId] = channel;
  }

  void unwatch(String userId) {
    _watchedChannels[userId]?.unsubscribe();
    _watchedChannels.remove(userId);
    final updated = Map<String, bool>.from(contactStatus.value);
    updated.remove(userId);
    contactStatus.value = updated;
  }

  bool isOnline(String userId) => contactStatus.value[userId] ?? false;

  Future<void> untrack() async {
    if (_myChannel == null) return;
    await _myChannel!.untrack();
    _myChannel!.unsubscribe();
    _myChannel = null;
  }

  void dispose() {
    for (final channel in _watchedChannels.values) {
      channel.unsubscribe();
    }
    _watchedChannels.clear();
    _myChannel?.unsubscribe();
    _myChannel = null;
  }
}
