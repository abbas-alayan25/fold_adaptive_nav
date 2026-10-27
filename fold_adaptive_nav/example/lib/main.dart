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

  @override
  Widget build(BuildContext context) {
    return FoldListener(
      onPostureChanged: (previous, current) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Posture: ${previous.name} → ${current.name}'),
      )),
      child: AdaptiveNavScaffold(
        destinations: _destinations,
        currentIndex: _tab,
        onSelect: (i) => setState(() => _tab = i),
        hideBarOnScroll: widget.settings.hideBarOnScroll,
        // A FAB on phones and tablets, the foot of the rail on the cover display.
        trailingAction: FloatingActionButton(
          tooltip: 'Scan',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scan tapped')),
          ),
          child: const Icon(Icons.qr_code_scanner),
        ),
        body: IndexedStack(
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
        ),
      ),
    );
  }
}
