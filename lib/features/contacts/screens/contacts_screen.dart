import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../chat/screens/chat_screen.dart';
import '../providers/contacts_provider.dart';
import '../widgets/request_tile.dart';
import 'add_contact_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(contactsProvider);
    ref.invalidate(pendingRequestCountProvider);
    ref.invalidate(receivedRequestsProvider);
    ref.invalidate(sentRequestsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final requestCountAsync = ref.watch(pendingRequestCountProvider);

    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      appBar: AppBar(title: const Text('Contacts')),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: Column(
          children: [
            _buildAddCards(),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.leafGreen,
              unselectedLabelColor: AppColors.earthBrown,
              indicatorColor: AppColors.leafGreen,
              tabs: [
                const Tab(text: 'Contacts'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Requests'),
                      requestCountAsync.whenOrNull(
                            data: (count) => count > 0
                                ? Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: AppColors.petalWhite,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : null,
                          ) ??
                          const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContactsTab(),
                  _buildRequestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _AddCard(
              icon: Icons.qr_code_scanner,
              label: 'Scan QR',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AddContactScreen(initialMode: AddContactMode.qr),
                  ),
                ).then((_) => _refresh());
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AddCard(
              icon: Icons.keyboard,
              label: 'Manual',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AddContactScreen(initialMode: AddContactMode.manual),
                  ),
                ).then((_) => _refresh());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsTab() {
    final contactsAsync = ref.watch(contactsProvider);

    return contactsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('$err', style: AppTextStyles.label),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _refresh,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
      data: (contacts) {
        if (contacts.isEmpty) {
          return ListView(
            children: [
              const SizedBox(height: 80),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 64, color: AppColors.sandyBrown),
                    const SizedBox(height: 16),
                    Text('No contacts yet', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Add contacts using QR or their tagar_id',
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: contacts.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final c = contacts[index];
            return ListTile(
              leading: AvatarWidget(
                name: c.displayName ?? c.profileName ?? c.contactTagarId,
                size: 48,
              ),
              title: Text(
                c.displayName ?? c.profileName ?? c.contactTagarId,
                style: AppTextStyles.bodyMedium,
              ),
              subtitle: Text(c.contactTagarId, style: AppTextStyles.caption),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                final displayName =
                    c.displayName ?? c.profileName ?? c.contactTagarId;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      contactName: displayName,
                      contactUserId: c.contactUserId,
                      contactTagarId: c.contactTagarId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    final receivedAsync = ref.watch(receivedRequestsProvider);
    final sentAsync = ref.watch(sentRequestsProvider);

    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        receivedAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('$err',
                style: const TextStyle(color: AppColors.error)),
          ),
          data: (requests) {
            if (requests.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('RECEIVED',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                ),
                ...requests.map((r) => IncomingRequestTile(
                      tagarId: r.fromTagarId,
                      onAccept: () async {
                        final svc = ref.read(contactServiceProvider);
                        try {
                          await svc.acceptRequest(
                              r.id, r.fromUserId, r.fromTagarId);
                          _refresh();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      },
                      onReject: () async {
                        final svc = ref.read(contactServiceProvider);
                        await svc.rejectRequest(r.id);
                        _refresh();
                      },
                    )),
              ],
            );
          },
        ),
        sentAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('$err',
                style: const TextStyle(color: AppColors.error)),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.send_outlined,
                          size: 48, color: AppColors.sandyBrown),
                      const SizedBox(height: 12),
                      Text('No requests sent yet',
                          style: AppTextStyles.label),
                    ],
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('SENT',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                ),
                ...requests.map((r) => SentRequestTile(
                      tagarId: r.fromTagarId,
                      status: r.status,
                    )),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.barkCream,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.leafGreen),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}
