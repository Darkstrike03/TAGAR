import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'message_storage_service.dart';

class StorageManagementService {
  final MessageStorageService _storage;

  StorageManagementService(this._storage);

  Future<int> getDatabaseSize() => _storage.getDatabaseSize();

  Future<int> getTotalMessageCount() => _storage.getMessageCount();

  Future<int> getConversationMessageCount(String conversationId) =>
      _storage.getConversationMessageCount(conversationId);

  Future<Directory> _cacheManagerDir() async {
    final tempDir = await getTemporaryDirectory();
    return Directory(p.join(tempDir.path, 'DefaultCacheManager'));
  }

  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _cacheManagerDir();
      int total = 0;
      if (cacheDir.existsSync()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            total += await entity.length();
          }
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      final cacheDir = await _cacheManagerDir();
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<void> deleteAllMessages() => _storage.deleteAllMessages();

  Future<void> deleteConversation(String conversationId) =>
      _storage.deleteConversation(conversationId);

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(size >= 100 ? 0 : (size >= 10 ? 1 : 2))} ${units[unitIndex]}';
  }
}
