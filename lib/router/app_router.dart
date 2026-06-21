import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.circle_outlined),
            activeIcon: Icon(Icons.circle),
            label: 'Updates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Store',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
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
            backgroundColor: const Color(0xFFEDE8DC),
            indicatorColor: const Color(0xFF5A8A3C),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'TAGAR',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF2E5220),
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
        final extra = state.extra as Map<String, String>? ?? {};
        return ChatScreen(
          contactName: extra['contactName'] ?? 'Unknown',
          contactUserId: contactUserId,
          contactTagarId: extra['contactTagarId'],
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
