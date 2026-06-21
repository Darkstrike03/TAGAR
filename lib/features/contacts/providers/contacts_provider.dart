import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/contact_model.dart';
import '../../../services/contact_service.dart';

final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});

final contactsProvider = FutureProvider<List<Contact>>((ref) {
  return ref.read(contactServiceProvider).getContacts();
});

final pendingRequestCountProvider = FutureProvider<int>((ref) {
  return ref.read(contactServiceProvider).getPendingRequestCount();
});

final receivedRequestsProvider = FutureProvider<List<FriendRequest>>((ref) {
  return ref.read(contactServiceProvider).getReceivedRequests();
});

final sentRequestsProvider = FutureProvider<List<FriendRequest>>((ref) {
  return ref.read(contactServiceProvider).getSentRequests();
});
