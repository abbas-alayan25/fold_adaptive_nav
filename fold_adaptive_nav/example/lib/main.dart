import 'package:flutter/material.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

import 'device_page.dart';
import 'gallery_page.dart';
import 'inbox_page.dart';
import 'player_page.dart';
import 'settings_page.dart';
import 'transfer_page.dart';

void main() {
  // No SystemChrome.setPreferredOrientations here: FoldScope sets them once
  // the first fold reading arrives.
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  var _settings = const ExampleSettings();

  @override
  Widget build(BuildContext context) {
    return FoldScope(
      config: _settings.config,
      child: MaterialApp(
        title: 'fold_adaptive_nav',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.teal),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
        ),
        locale: _settings.rtl ? const Locale('ar') : null,
        // Pins the form factor below this point, to preview the cover and
        // tablet layouts on any device.
        builder: (context, child) {
          // Shows what the package sees: form factor, posture, the fold.
          Widget app =
              FoldDebugOverlay(enabled: _settings.debugOverlay, child: child!);
          if (_settings.preview case final FormFactor preview) {
            app = FormFactorOverride(formFactor: preview, child: app);
          }
          return Directionality(
            textDirection:
                _settings.rtl ? TextDirection.rtl : TextDirection.ltr,
            child: app,
          );
        },
        home: HomeShell(
          settings: _settings,
          onSettingsChanged: (s) => setState(() => _settings = s),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final ExampleSettings settings;
  final ValueChanged<ExampleSettings> onSettingsChanged;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  // Six tabs: the bar and the cover rail show four and "More"; the tablet
  // rail and drawer show all of them.
  static const _destinations = [
    NavDestination(
      icon: Icons.devices_fold_outlined,
      selectedIcon: Icons.devices_fold,
      label: 'Device',
    ),
    NavDestination(
      icon: Icons.inbox_outlined,
      selectedIcon: Icons.inbox,
      label: 'Inbox',
      badge: '3',
    ),
    NavDestination(
      icon: Icons.swap_horiz_outlined,
      selectedIcon: Icons.swap_horiz,
      label: 'Transfer',
    ),
    NavDestination(
      icon: Icons.play_circle_outline,
      selectedIcon: Icons.play_circle,
      label: 'Player',
    ),
    NavDestination(
      icon: Icons.photo_library_outlined,
      selectedIcon: Icons.photo_library,
      label: 'Gallery',
    ),
    NavDestination(
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
      label: 'Settings',
    ),
  ];

  // The same tabs in groups, in the same order, so the page indexes match.
  static final _groups = [
    NavGroup(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
      destinations: _destinations.sublist(0, 2),
    ),
    NavGroup(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: 'Money',
      destinations: _destinations.sublist(2, 3),
    ),
    NavGroup(
      icon: Icons.perm_media_outlined,
      selectedIcon: Icons.perm_media,
      label: 'Media',
      destinations: _destinations.sublist(3, 5),
    ),
    NavGroup(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'App',
      destinations: _destinations.sublist(5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // A FAB on phones and tablets, the foot of the rail on the cover display.
    final scan = FloatingActionButton(
      tooltip: 'Scan',
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan tapped')),
      ),
      child: const Icon(Icons.qr_code_scanner),
    );
    final body = IndexedStack(
      index: _tab,
      children: [
        const DevicePage(),
        const InboxPage(),
        const TransferPage(),
        const PlayerPage(),
        const GalleryPage(),
        SettingsPage(
          settings: widget.settings,
          onChanged: widget.onSettingsChanged,
        ),
      ],
    );
    void select(int i) => setState(() => _tab = i);
    final hide = widget.settings.hideBarOnScroll;
    return FoldListener(
      onPostureChanged: (previous, current) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Posture: ${previous.name} → ${current.name}'),
      )),
      // Same widget type either way, so switching keeps the pages' state.
      child: widget.settings.groupTabs
          ? AdaptiveNavScaffold.grouped(
              groups: _groups,
              currentIndex: _tab,
              onSelect: select,
              hideBarOnScroll: hide,
              trailingAction: scan,
              body: body,
            )
          : AdaptiveNavScaffold(
              destinations: _destinations,
              currentIndex: _tab,
              onSelect: select,
              hideBarOnScroll: hide,
              trailingAction: scan,
              body: body,
            ),
    );
  }
}
