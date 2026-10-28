import 'package:flutter/material.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';
import 'package:go_router/go_router.dart';

/// fold_adaptive_nav with go_router.
///
/// `StatefulShellRoute.indexedStack` keeps a back stack per tab, and
/// `AdaptiveNavScaffold` only needs the shell's index and `goBranch`:
/// the tabs move to the thumb on every device, and a deep link such as
/// `/orders/42` opens the right tab with its page on top.
void main() => runApp(
      FoldScope(
        config: const FoldAdaptiveConfig(
          tabletNavigation: TabletNavigation.railInLandscape,
          tabletRailStyle: TabletRailStyle.expanded,
        ),
        child: MaterialApp.router(
          title: 'fold_adaptive_nav + go_router',
          theme: ThemeData(colorSchemeSeed: Colors.indigo),
          routerConfig: router,
        ),
      ),
    );

const _tabs = [
  NavDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Home',
  ),
  NavDestination(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    label: 'Orders',
  ),
  NavDestination(
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: 'Profile',
  ),
];

/// The app's routes. Public so tests can start it at any location.
GoRouter buildRouter({String initialLocation = '/home'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AdaptiveNavScaffold(
            destinations: _tabs,
            currentIndex: shell.currentIndex,
            // Tapping the current tab again goes back to its first page.
            onSelect: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            body: shell,
          ),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const _Page(
                  title: 'Home',
                  text: 'Open Orders, open an order, then come back to Home '
                      'and Orders again: each tab keeps its own pages.',
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const _OrderList(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        _OrderPage(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const _Page(
                  title: 'Profile',
                  text: 'Fold or unfold: the tab, its pages and their scroll '
                      'positions stay.',
                ),
              ),
            ]),
          ],
        ),
      ],
    );

/// The router the app runs with.
final router = buildRouter();

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
      );
}

class _OrderList extends StatelessWidget {
  const _OrderList();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            for (var id = 40; id < 60; id++)
              ListTile(
                title: Text('Order #$id'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/orders/$id'),
              ),
          ],
        ),
      );
}

class _OrderPage extends StatelessWidget {
  const _OrderPage({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Order #$id')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Deep link: /orders/$id'),
        ),
      );
}
