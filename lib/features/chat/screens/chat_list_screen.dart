import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../models/contact_model.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/presence_provider.dart';
import '../../../services/message_storage_service.dart';
import '../../../router/route_names.dart';
import '../../contacts/providers/contacts_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  Contact? _selectedContact;

  @override
  void initState() {
    super.initState();
    final relay = ref.read(messageRelayProvider);
    relay.subscribeToIncoming();
    relay.messageNotifier.addListener(_onMessageEvent);
    ref.read(presenceServiceProvider).track();
  }

  void _onMessageEvent() {
    ref.invalidate(conversationsProvider);
  }

  @override
  void dispose() {
    ref.read(messageRelayProvider).messageNotifier.removeListener(_onMessageEvent);
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(contactsProvider);
    ref.invalidate(conversationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildLandscapeLayout();
          } else {
            return _buildPortraitLayout();
          }
        },
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'contacts') {
                context.push('/contacts');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'contacts',
                child: ListTile(
                  leading: Icon(Icons.contacts_outlined),
                  title: Text('Contacts'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: Column(
          children: [
            _SearchBar(),
            const Divider(height: 1, color: AppColors.sandyBrown),
            Expanded(child: _buildChatList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/contacts');
          _refresh();
        },
        backgroundColor: AppColors.leafGreen,
        foregroundColor: AppColors.petalWhite,
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        SizedBox(
          width: 350,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Chats'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: () {},
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'contacts') {
                      context.push('/contacts');
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'contacts',
                      child: ListTile(
                        leading: Icon(Icons.contacts_outlined),
                        title: Text('Contacts'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: Column(
                children: [
                  _SearchBar(),
                  const Divider(height: 1, color: AppColors.sandyBrown),
                  Expanded(child: _buildChatList()),
                ],
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: _selectedContact != null
              ? ChatScreen(
                  contactName: _selectedContact!.displayName ??
                      _selectedContact!.profileName ??
                      _selectedContact!.contactTagarId,
                  contactUserId: _selectedContact!.contactUserId,
                  contactTagarId: _selectedContact!.contactTagarId,
                  contactProfilePicture: _selectedContact!.profilePicture,
                  showBackButton: false,
                )
              : _buildEmptyDetailView(),
        ),
      ],
    );
  }

  Widget _buildEmptyDetailView() {
    return Container(
      color: AppColors.barkCream.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.petalWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppColors.leafGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tagar for Web/Desktop',
              style: AppTextStyles.h1.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a chat to start blooming conversations.',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    size: 14, color: AppColors.earthBrown),
                const SizedBox(width: 4),
                Text(
                  'End-to-end encrypted',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    final contactsAsync = ref.watch(contactsProvider);
    final conversationsAsync = ref.watch(conversationsProvider);

    return contactsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildError(err.toString()),
      data: (contacts) {
        if (contacts.isEmpty) {
          return _buildEmptyContacts();
        }
        return conversationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildChatItems(contacts, []),
          data: (conversations) =>
              _buildChatItems(contacts, conversations),
        );
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyles.label),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _refresh,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyContacts() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 64, color: AppColors.sandyBrown),
              const SizedBox(height: 16),
              Text('No chats yet', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                'Add contacts to start a conversation',
                style: AppTextStyles.label,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatItems(
      List<Contact> contacts, List<ConversationSummary> conversations) {
    final conversationMap = {
      for (final c in conversations) c.conversationId: c,
    };

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.5,
        indent: 64,
        color: AppColors.sandyBrown,
      ),
      itemBuilder: (_, index) {
        final contact = contacts[index];
        final conv = conversationMap[contact.contactUserId];
        final isSelected =
            _selectedContact?.contactUserId == contact.contactUserId;
        final displayName = contact.displayName ??
            contact.profileName ??
            contact.contactTagarId;
        final hasUnread = (conv?.unreadCount ?? 0) > 0;

        return InkWell(
          onTap: () {
            final isLandscape =
                MediaQuery.of(context).size.width > 900;
            if (isLandscape) {
              setState(() => _selectedContact = contact);
            } else {
              context.pushNamed(
                RouteNames.chat,
                pathParameters: {'contactUserId': contact.contactUserId},
                extra: {
                  'contactName': displayName,
                  'contactTagarId': contact.contactTagarId,
                  'contactProfilePicture': contact.profilePicture,
                },
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.barkCream : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                AvatarWidget(
                  name: displayName,
                  imageUrl: contact.profilePicture,
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            displayName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: isSelected || hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                          if (conv != null)
                            Text(
                              _formatTimestamp(conv.lastTimestamp),
                              style: AppTextStyles.caption.copyWith(
                                color: hasUnread
                                    ? AppColors.leafGreen
                                    : AppColors.earthBrown,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (hasUnread)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.done_all,
                                size: 16,
                                color: AppColors.riverBlue,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              conv?.lastMessage ??
                                  'Start a conversation',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: hasUnread
                                    ? AppColors.forestGreen
                                    : AppColors.earthBrown,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.leafGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${conv!.unreadCount}',
                                style: const TextStyle(
                                  color: AppColors.petalWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(int milliseconds) {
    final dt =
        DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      final h =
          dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $amPm';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: AppTextStyles.label,
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.earthBrown,
          ),
          filled: true,
          fillColor: AppColors.barkCream,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
