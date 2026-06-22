import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/presence_provider.dart';
import '../../../services/message_storage_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String contactName;
  final String contactUserId;
  final String? contactTagarId;
  final String? contactProfilePicture;
  final bool showBackButton;

  const ChatScreen({
    super.key,
    required this.contactName,
    required this.contactUserId,
    this.contactTagarId,
    this.contactProfilePicture,
    this.showBackButton = true,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<LocalMessage> _messages = [];
  bool _loading = true;
  bool _isOnline = false;
  late final _messageNotifier =
      ref.read(messageRelayProvider).messageNotifier;
  late final _presenceService =
      ref.read(presenceServiceProvider);

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenForNewMessages();
    _markAsRead();
    _initPresence();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _messageNotifier.removeListener(_onNewMessage);
    _presenceService.contactStatus.removeListener(_onPresenceChanged);
    _presenceService.unwatch(widget.contactUserId);
    super.dispose();
  }

  void _initPresence() {
    _presenceService.watch(widget.contactUserId);
    _isOnline = _presenceService.isOnline(widget.contactUserId);
    _presenceService.contactStatus.addListener(_onPresenceChanged);
  }

  void _onPresenceChanged() {
    if (!mounted) return;
    setState(() {
      _isOnline = _presenceService.isOnline(widget.contactUserId);
    });
  }

  Future<void> _loadMessages() async {
    try {
      final storage = ref.read(messageStorageProvider);
      final messages = await storage.getMessages(widget.contactUserId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _listenForNewMessages() {
    _messageNotifier.addListener(_onNewMessage);
    try {
      ref.read(messageRelayProvider).subscribeToIncoming();
    } catch (_) {}
  }

  void _onNewMessage() {
    _loadMessages();
  }

  Future<void> _markAsRead() async {
    final storage = ref.read(messageStorageProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    await storage.markAsRead(widget.contactUserId, userId);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    final relay = ref.read(messageRelayProvider);
    await relay.sendMessage(
      receiverId: widget.contactUserId,
      text: text,
    );

    final storage = ref.read(messageStorageProvider);
    final messages = await storage.getMessages(widget.contactUserId);
    if (!mounted) return;
    setState(() => _messages = messages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.barkCream,
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : const SizedBox(width: 18),
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarWidget(
              name: widget.contactName,
              imageUrl: widget.contactProfilePicture,
              size: 38,
              isOnline: _isOnline,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
                ),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: AppTextStyles.caption.copyWith(
                    color: _isOnline ? AppColors.leafGreen : AppColors.sandyBrown,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Start a conversation with ${widget.contactName}',
                            style: AppTextStyles.label,
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          itemCount: _messages.length,
                          itemBuilder: (_, index) {
                            final msg = _messages[index];
                            final userId = Supabase.instance.client.auth
                                    .currentUser?.id ??
                                '';
                            return MessageBubble(
                              text: msg.text,
                              isSent: msg.senderId == userId,
                              time: _formatTime(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      msg.timestamp)),
                              isRead: msg.status == 'read',
                            );
                          },
                        ),
                ),
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: const BoxDecoration(
        color: AppColors.petalWhite,
        border: Border(
          top: BorderSide(color: AppColors.sandyBrown, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.attach_file_outlined,
                color: AppColors.earthBrown,
              ),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: AppTextStyles.label,
                  filled: true,
                  fillColor: AppColors.barkCream,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: AppColors.leafGreen,
              ),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $amPm';
  }
}
