import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/presence_service.dart';

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final svc = PresenceService();
  ref.onDispose(() => svc.dispose());
  return svc;
});
