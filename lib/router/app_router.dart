import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/splash/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/updates/screens/updates_screen.dart';
import '../features/language_store/screens/language_store_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/contacts/screens/contacts_screen.dart';
import '../features/contacts/screens/add_contact_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../core/theme/app_colors.dart';
import 'route_names.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 900) {
        return _buildWideLayout();
      }
      return _buildNarrowLayout();
    });
  }

  Widget _buildNarrowLayout() {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) =>
                navigationShell.goBranch(index),
            backgroundColor: AppColors.barkCream,
            indicatorColor: AppColors.leafGreen.withValues(alpha: 0.2),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline,
                    color: AppColors.earthBrown),
                selectedIcon: Icon(Icons.chat_bubble,
                    color: AppColors.leafGreen),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.circle_outlined,
                    color: AppColors.earthBrown),
                selectedIcon: Icon(Icons.circle,
                    color: AppColors.leafGreen),
                label: 'Updates',
              ),
              NavigationDestination(
                icon: Icon(Icons.store_outlined,
                    color: AppColors.earthBrown),
                selectedIcon: Icon(Icons.store,
                    color: AppColors.leafGreen),
                label: 'Store',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline,
                    color: AppColors.earthBrown),
                selectedIcon: Icon(Icons.person,
                    color: AppColors.leafGreen),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) =>
                navigationShell.goBranch(index),
            labelType: NavigationRailLabelType.all,
            backgroundColor: AppColors.barkCream,
            indicatorColor: AppColors.leafGreen,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'TAGAR',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.forestGreen,
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('Chat'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.circle_outlined),
                selectedIcon: Icon(Icons.circle),
                label: Text('Updates'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.store_outlined),
                selectedIcon: Icon(Icons.store),
                label: Text('Store'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    final onAuthPage = state.matchedLocation == '/splash' ||
        state.matchedLocation == '/login';
    if (!isLoggedIn && !onAuthPage) return '/login';
    if (isLoggedIn && onAuthPage) return '/chat';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      name: RouteNames.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: RouteNames.login,
      builder: (_, __) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, __, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              name: RouteNames.chatList,
              builder: (_, __) => const ChatListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/updates',
              name: RouteNames.updates,
              builder: (_, __) => const UpdatesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/store',
              name: RouteNames.languageStore,
              builder: (_, __) => const LanguageStoreScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: RouteNames.profile,
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/chat/:contactUserId',
      name: RouteNames.chat,
      builder: (_, state) {
        final contactUserId = state.pathParameters['contactUserId']!;
        final extra = state.extra as Map<String, String?>? ?? {};
        return ChatScreen(
          contactName: extra['contactName'] ?? 'Unknown',
          contactUserId: contactUserId,
          contactTagarId: extra['contactTagarId'],
          contactProfilePicture: extra['contactProfilePicture'],
        );
      },
    ),
    GoRoute(
      path: '/contacts',
      name: RouteNames.contacts,
      builder: (_, __) => const ContactsScreen(),
    ),
    GoRoute(
      path: '/contacts/add',
      name: RouteNames.addContact,
      builder: (_, __) => const AddContactScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: RouteNames.settings,
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
);
