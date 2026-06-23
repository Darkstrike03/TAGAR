import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalMessage {
  final String id;
  final String conversationId;
  final String text;
  final String senderId;
  final int timestamp;
  final String status;

  LocalMessage({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversation_id': conversationId,
        'text': text,
        'sender_id': senderId,
        'timestamp': timestamp,
        'status': status,
      };

  factory LocalMessage.fromMap(Map<String, dynamic> map) => LocalMessage(
        id: map['id'] as String,
        conversationId: map['conversation_id'] as String,
        text: map['text'] as String,
        senderId: map['sender_id'] as String,
        timestamp: map['timestamp'] as int,
        status: map['status'] as String,
      );
}

class ConversationSummary {
  final String conversationId;
  final String lastMessage;
  final int lastTimestamp;
  final int unreadCount;

  ConversationSummary({
    required this.conversationId,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.unreadCount,
  });
}

class MessageStorageService {
  static Database? _db;

  static Future<DatabaseFactory> _resolveFactory() async {
    try {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    } catch (_) {
      return databaseFactory;
    }
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final factory = await _resolveFactory();
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'tagar_messages.db');
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE messages (
              id TEXT PRIMARY KEY,
              conversation_id TEXT NOT NULL,
              text TEXT NOT NULL,
              sender_id TEXT NOT NULL,
              timestamp INTEGER NOT NULL,
              status TEXT NOT NULL DEFAULT 'sent'
            )
          ''');
          await db.execute('''
            CREATE INDEX idx_conversation_id ON messages(conversation_id)
          ''');
          await db.execute('''
            CREATE INDEX idx_timestamp ON messages(timestamp)
          ''');
        },
      ),
    );
  }

  Future<void> insertMessage(LocalMessage message) async {
    final db = await database;
    await db.insert('messages', message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LocalMessage>> getMessages(String conversationId,
      {int limit = 50, int? offset}) async {
    final db = await database;
    final maps = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
      limit: limit,
      offset: offset,
    );
    return maps.map(LocalMessage.fromMap).toList();
  }

  Future<List<ConversationSummary>> getConversations() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT
        conversation_id,
        (SELECT text FROM messages m2
          WHERE m2.conversation_id = m1.conversation_id
          ORDER BY timestamp DESC LIMIT 1) as last_message,
        MAX(timestamp) as last_timestamp,
        (SELECT COUNT(*) FROM messages m3
          WHERE m3.conversation_id = m1.conversation_id
            AND m3.sender_id != m3.conversation_id
            AND m3.status = 'received') as unread_count
      FROM messages m1
      GROUP BY conversation_id
      ORDER BY last_timestamp DESC
    ''');
    return maps.map((m) => ConversationSummary(
          conversationId: m['conversation_id'] as String,
          lastMessage: m['last_message'] as String? ?? '',
          lastTimestamp: m['last_timestamp'] as int,
          unreadCount: (m['unread_count'] as int?) ?? 0,
        )).toList();
  }

  Future<int> getUnreadCount(String conversationId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM messages
      WHERE conversation_id = ?
        AND sender_id != conversation_id
        AND status = 'received'
    ''', [conversationId]);
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> markAsRead(String conversationId, String currentUserId) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': 'read'},
      where:
          'conversation_id = ? AND sender_id != ? AND status = \'received\'',
      whereArgs: [conversationId, currentUserId],
    );
  }

  Future<void> markAsDelivered(String messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': 'delivered'},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    final db = await database;
    await db.delete('messages',
        where: 'conversation_id = ?', whereArgs: [conversationId]);
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
  }

  Future<int> getMessageCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM messages');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getConversationMessageCount(String conversationId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE conversation_id = ?',
      [conversationId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<String> getDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'tagar_messages.db');
  }

  Future<int> getDatabaseSize() async {
    final path = await getDatabasePath();
    try {
      return File(path).statSync().size;
    } catch (_) {
      return 0;
    }
  }

  Future<void> deleteAllMessages() async {
    final db = await database;
    await db.delete('messages');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
