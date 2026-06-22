import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact_model.dart';

class ContactService {
  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  Future<String> getMyTagarId() async {
    final response = await Supabase.instance.client
        .from('user_data')
        .select('tagar_id')
        .eq('id', _userId)
        .single();
    return response['tagar_id'] as String;
  }

  Future<List<Contact>> getContacts() async {
    final response = await Supabase.instance.client
        .from('contacts')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: true);
    final contacts =
        (response as List).map((e) => Contact.fromJson(e)).toList();

    if (contacts.isEmpty) return contacts;

    final userIds = contacts.map((c) => c.contactUserId).toList();
    final userDataResponse = await Supabase.instance.client
        .from('user_data')
        .select('id, profile_name, profile_picture')
        .inFilter('id', userIds);

    final profileMap = {
      for (final row in (userDataResponse as List))
        row['id'] as String: {
          'profile_name': row['profile_name'] as String?,
          'profile_picture': row['profile_picture'] as String?,
        },
    };

    return contacts.map((c) {
      final data = profileMap[c.contactUserId];
      return Contact(
        id: c.id,
        userId: c.userId,
        contactUserId: c.contactUserId,
        contactTagarId: c.contactTagarId,
        displayName: c.displayName,
        profileName: data?['profile_name'],
        profilePicture: data?['profile_picture'],
        createdAt: c.createdAt,
      );
    }).toList();
  }

  Future<int> getPendingRequestCount() async {
    final response = await Supabase.instance.client
        .from('friend_requests')
        .select('id')
        .or('to_user_id.eq.$_userId,from_user_id.eq.$_userId')
        .eq('status', 'pending');
    return response.length;
  }

  Future<List<FriendRequest>> getReceivedRequests() async {
    final response = await Supabase.instance.client
        .from('friend_requests')
        .select()
        .eq('to_user_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (response as List).map((e) => FriendRequest.fromJson(e)).toList();
  }

  Future<List<FriendRequest>> getSentRequests() async {
    final response = await Supabase.instance.client
        .from('friend_requests')
        .select()
        .eq('from_user_id', _userId)
        .order('created_at', ascending: false);
    final requests =
        (response as List).map((e) => FriendRequest.fromJson(e)).toList();

    for (final r in requests) {
      if (r.status == 'accepted') {
        await _createReverseContactIfMissing(r.toUserId);
      }
    }

    return requests;
  }

  Future<void> _createReverseContactIfMissing(String otherUserId) async {
    final existing = await Supabase.instance.client
        .from('contacts')
        .select('id')
        .eq('user_id', _userId)
        .eq('contact_user_id', otherUserId)
        .maybeSingle();

    if (existing != null) return;

    final otherUser = await Supabase.instance.client
        .from('user_data')
        .select('tagar_id')
        .eq('id', otherUserId)
        .single();
    final otherTagarId = otherUser['tagar_id'] as String;

    await Supabase.instance.client.from('contacts').insert({
      'user_id': _userId,
      'contact_user_id': otherUserId,
      'contact_tagar_id': otherTagarId,
    });
  }

  Future<Map<String, dynamic>?> findUserByTagarId(String tagarId) async {
    final response = await Supabase.instance.client
        .from('user_data')
        .select('id, profile_name, tagar_id')
        .eq('tagar_id', tagarId)
        .neq('id', _userId)
        .maybeSingle();
    return response;
  }

  Future<void> sendRequest(String toUserId, String toTagarId) async {
    final tagarId = await getMyTagarId();
    await Supabase.instance.client.from('friend_requests').insert({
      'from_user_id': _userId,
      'to_user_id': toUserId,
      'from_tagar_id': tagarId,
    });
  }

  Future<void> acceptRequest(
    String requestId,
    String fromUserId,
    String fromTagarId,
  ) async {
    await Supabase.instance.client.from('friend_requests').update({
      'status': 'accepted',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);

    await Supabase.instance.client.from('contacts').upsert({
      'user_id': _userId,
      'contact_user_id': fromUserId,
      'contact_tagar_id': fromTagarId,
    });
  }

  Future<void> rejectRequest(String requestId) async {
    await Supabase.instance.client.from('friend_requests').update({
      'status': 'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }
}
