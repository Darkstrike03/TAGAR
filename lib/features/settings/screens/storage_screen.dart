import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/contacts/providers/contacts_provider.dart';
import '../../../providers/message_provider.dart';
import '../../../services/storage_management_service.dart';
import '../../../services/message_storage_service.dart';

class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  int _dbSize = 0;
  int _cacheSize = 0;
  int _totalMessages = 0;
  List<ConversationSummary> _conversations = [];
  Map<String, String> _contactNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final mgmt = ref.read(storageManagementProvider);
    final contactsAsync = ref.read(contactsProvider);

    final dbSize = await mgmt.getDatabaseSize();
    final cacheSize = await mgmt.getCacheSize();
    final totalMessages = await mgmt.getTotalMessageCount();
    final storage = ref.read(messageStorageProvider);
    final conversations = await storage.getConversations();

    final names = <String, String>{};
    final contacts = contactsAsync.valueOrNull ?? [];
    for (final c in contacts) {
      names[c.contactUserId] = c.displayName ?? c.profileName ?? c.contactTagarId;
    }

    if (!mounted) return;
    setState(() {
      _dbSize = dbSize;
      _cacheSize = cacheSize;
      _totalMessages = totalMessages;
      _conversations = conversations;
      _contactNames = names;
      _loading = false;
    });
  }

  Future<void> _deleteConversation(String conversationId) async {
    final name = _contactNames[conversationId] ?? 'this conversation';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Delete all messages with $name? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final mgmt = ref.read(storageManagementProvider);
      await mgmt.deleteConversation(conversationId);
      _loadData();
    }
  }

  Future<void> _deleteAllMessages() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Chats'),
        content: const Text(
          'This will permanently delete all messages from all conversations. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final mgmt = ref.read(storageManagementProvider);
      await mgmt.deleteAllMessages();
      _loadData();
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear cached images and temporary files. '
          'They will be re-downloaded when needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final mgmt = ref.read(storageManagementProvider);
      await mgmt.clearCache();
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      appBar: AppBar(title: const Text('Storage & Data')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildUsageCard(),
                  const SizedBox(height: 20),
                  if (_conversations.isNotEmpty) ...[
                    _section('Chats (${_conversations.length})'),
                    const SizedBox(height: 4),
                    ..._conversations.map(_buildConversationTile),
                    const SizedBox(height: 16),
                  ],
                  _section('Clear Data'),
                  const SizedBox(height: 4),
                  _buildDeleteAllButton(),
                  const SizedBox(height: 8),
                  _buildClearCacheButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildUsageCard() {
    final total = _dbSize + _cacheSize;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.sandyBrown.withValues(alpha: 0.3)),
      ),
      color: AppColors.barkCream,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage_rounded,
                    color: AppColors.leafGreen, size: 20),
                const SizedBox(width: 8),
                Text('Storage Usage',
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 20,
                child: Row(
                  children: [
                    if (_dbSize > 0)
                      Expanded(
                        flex: (_dbSize * 100 ~/ (total > 0 ? total : 1)),
                        child: Container(
                          color: AppColors.leafGreen,
                          child: Center(
                            child: Text(
                              _dbSize > total ~/ 20
                                  ? 'Messages'
                                  : '',
                              style: const TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_cacheSize > 0)
                      Expanded(
                        flex: (_cacheSize * 100 ~/ (total > 0 ? total : 1)),
                        child: Container(
                          color: AppColors.riverBlue,
                          child: Center(
                            child: Text(
                              _cacheSize > total ~/ 20
                                  ? 'Cache'
                                  : '',
                              style: const TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (total == 0)
                      Expanded(
                        child: Container(
                          color: AppColors.sandyBrown,
                          child: Center(
                            child: Text(
                              'No data',
                              style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _storageRow(
              Icons.chat_bubble_outline,
              'Messages',
              StorageManagementService.formatBytes(_dbSize),
              '$_totalMessages messages',
              AppColors.leafGreen,
            ),
            const SizedBox(height: 8),
            _storageRow(
              Icons.image_outlined,
              'Cache',
              StorageManagementService.formatBytes(_cacheSize),
              'Profile images & temp files',
              AppColors.riverBlue,
            ),
            const Divider(height: 24),
            _storageRow(
              Icons.sd_storage_outlined,
              'Total',
              StorageManagementService.formatBytes(total),
              '',
              AppColors.forestGreen,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _storageRow(IconData icon, String label, String size, String subtitle,
      Color color, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: (bold ? AppTextStyles.bodyMedium : AppTextStyles.body)
                  .copyWith(fontSize: 14),
            ),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 11)),
          ],
        ),
        const Spacer(),
        Text(
          size,
          style: (bold ? AppTextStyles.bodyMedium : AppTextStyles.body)
              .copyWith(fontSize: 14, color: AppColors.forestGreen),
        ),
      ],
    );
  }

  Widget _buildConversationTile(ConversationSummary conv) {
    final name = _contactNames[conv.conversationId] ?? conv.conversationId;
    final isId = _contactNames[conv.conversationId] == null;
    final displayName = isId
        ? 'User ${conv.conversationId.substring(0, 8)}...'
        : name;

    return Dismissible(
      key: ValueKey('conv_${conv.conversationId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _deleteConversation(conv.conversationId);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.barkCream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.leafGreen.withValues(alpha: 0.2),
            child: Text(
              displayName.isNotEmpty
                  ? displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontWeight: FontWeight.w600,
                color: AppColors.forestGreen,
              ),
            ),
          ),
          title: Text(
            displayName,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            conv.lastMessage.isNotEmpty ? conv.lastMessage : 'No messages',
            style: AppTextStyles.caption.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            conv.unreadCount > 0 ? conv.unreadCount.toString() : '',
            style: AppTextStyles.caption.copyWith(fontSize: 12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onLongPress: () => _deleteConversation(conv.conversationId),
        ),
      ),
    );
  }

  Widget _buildDeleteAllButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _conversations.isEmpty ? null : _deleteAllMessages,
        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
        label: const Text('Delete All Chats'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildClearCacheButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _cacheSize == 0 ? null : _clearCache,
        icon: const Icon(Icons.cleaning_services_outlined, size: 18),
        label: Text(
            _cacheSize == 0 ? 'Cache Empty' : 'Clear Cache'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title.toUpperCase(), style: AppTextStyles.caption),
    );
  }
}
