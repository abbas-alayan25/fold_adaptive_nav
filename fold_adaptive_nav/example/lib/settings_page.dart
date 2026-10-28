import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

/// What the settings tab can change, at runtime.
@immutable
class ExampleSettings {
  const ExampleSettings({
    this.tabletNavigation = TabletNavigation.bottomBar,
    this.coverRailSide = RailSide.trailingPhysicalRight,
    this.coverRailAlignment = CoverRailAlignment.bottom,
    this.lockPhonesToPortrait = true,
    this.preview,
    this.rtl = false,
    this.hideBarOnScroll = false,
    this.drawerOnWideTablets = false,
    this.narrowCoversAsPhones = false,
    this.flipsAsPhones = true,
    this.debugOverlay = false,
    this.tabletRailStyle = TabletRailStyle.standard,
    this.tabletRailAlignment = CoverRailAlignment.top,
    this.groupTabs = false,
    this.look = NavLook.material,
  });

  final TabletNavigation tabletNavigation;
  final RailSide coverRailSide;
  final CoverRailAlignment coverRailAlignment;
  final bool lockPhonesToPortrait;

  /// Pins the form factor, or null to follow the device.
  final FormFactor? preview;
  final bool rtl;
  final bool hideBarOnScroll;
  final bool drawerOnWideTablets;
  final bool narrowCoversAsPhones;
  final bool flipsAsPhones;
  final bool debugOverlay;
  final TabletRailStyle tabletRailStyle;
  final CoverRailAlignment tabletRailAlignment;

  /// Puts the tabs under groups, which side bars open one at a time.
  final bool groupTabs;

  /// Material or Cupertino bars and side bars.
  final NavLook look;

  FoldAdaptiveConfig get config => FoldAdaptiveConfig(
        tabletNavigation: tabletNavigation,
        coverRailSide: coverRailSide,
        coverRailAlignment: coverRailAlignment,
        lockPhonesToPortrait: lockPhonesToPortrait,
        coverOrientations: const [DeviceOrientation.portraitUp],
        drawerFromWidth: drawerOnWideTablets ? 1200 : null,
        // Galaxy Z Fold covers (344–373 pt) get the bottom bar; the Pixel
        // Fold and iPhone Duo covers keep the rail.
        coverMinShortestSide: narrowCoversAsPhones ? 380 : 0,
        treatOpenedFlipsAsPhones: flipsAsPhones,
        tabletRailStyle: tabletRailStyle,
        tabletRailAlignment: tabletRailAlignment,
      );

  ExampleSettings copyWith({
    TabletNavigation? tabletNavigation,
    RailSide? coverRailSide,
    CoverRailAlignment? coverRailAlignment,
    bool? lockPhonesToPortrait,
    FormFactor? Function()? preview,
    bool? rtl,
    bool? hideBarOnScroll,
    bool? drawerOnWideTablets,
    bool? narrowCoversAsPhones,
    bool? flipsAsPhones,
    bool? debugOverlay,
    TabletRailStyle? tabletRailStyle,
    CoverRailAlignment? tabletRailAlignment,
    bool? groupTabs,
    NavLook? look,
  }) =>
      ExampleSettings(
        tabletNavigation: tabletNavigation ?? this.tabletNavigation,
        coverRailSide: coverRailSide ?? this.coverRailSide,
        coverRailAlignment: coverRailAlignment ?? this.coverRailAlignment,
        lockPhonesToPortrait: lockPhonesToPortrait ?? this.lockPhonesToPortrait,
        preview: preview != null ? preview() : this.preview,
        rtl: rtl ?? this.rtl,
        hideBarOnScroll: hideBarOnScroll ?? this.hideBarOnScroll,
        drawerOnWideTablets: drawerOnWideTablets ?? this.drawerOnWideTablets,
        narrowCoversAsPhones: narrowCoversAsPhones ?? this.narrowCoversAsPhones,
        flipsAsPhones: flipsAsPhones ?? this.flipsAsPhones,
        debugOverlay: debugOverlay ?? this.debugOverlay,
        tabletRailStyle: tabletRailStyle ?? this.tabletRailStyle,
        tabletRailAlignment: tabletRailAlignment ?? this.tabletRailAlignment,
        groupTabs: groupTabs ?? this.groupTabs,
        look: look ?? this.look,
      );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final ExampleSettings settings;
  final ValueChanged<ExampleSettings> onChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _verticalBarDisabled = true;

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Text('Settings', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          const _Header('Preview layout'),
          SegmentedButton<FormFactor?>(
            segments: const [
              ButtonSegment(value: null, label: Text('Auto')),
              ButtonSegment(value: FormFactor.phone, label: Text('Phone')),
              ButtonSegment(value: FormFactor.cover, label: Text('Cover')),
              ButtonSegment(value: FormFactor.tablet, label: Text('Tablet')),
            ],
            selected: {s.preview},
            onSelectionChanged: (v) =>
                widget.onChanged(s.copyWith(preview: () => v.first)),
          ),
          const _Header('Look'),
          SegmentedButton<NavLook>(
            segments: const [
              ButtonSegment(value: NavLook.material, label: Text('Material')),
              ButtonSegment(value: NavLook.cupertino, label: Text('Cupertino')),
              ButtonSegment(value: NavLook.platform, label: Text('Platform')),
            ],
            selected: {s.look},
            onSelectionChanged: (v) =>
                widget.onChanged(s.copyWith(look: v.first)),
          ),
          const _Header('Tablet navigation'),
          SegmentedButton<TabletNavigation>(
            segments: const [
              ButtonSegment(
                value: TabletNavigation.bottomBar,
                label: Text('Bottom'),
              ),
              ButtonSegment(value: TabletNavigation.rail, label: Text('Side')),
              ButtonSegment(
                value: TabletNavigation.railInLandscape,
                label: Text('Landscape'),
              ),
            ],
            selected: {s.tabletNavigation},
            onSelectionChanged: (v) =>
                widget.onChanged(s.copyWith(tabletNavigation: v.first)),
          ),
          const _Header('Tablet side bar'),
          SegmentedButton<TabletRailStyle>(
            segments: const [
              ButtonSegment(
                value: TabletRailStyle.standard,
                label: Text('Icons'),
              ),
              ButtonSegment(
                value: TabletRailStyle.expanded,
                label: Text('Expanded'),
              ),
            ],
            selected: {s.tabletRailStyle},
            onSelectionChanged: (v) =>
                widget.onChanged(s.copyWith(tabletRailStyle: v.first)),
          ),
          const SizedBox(height: 8),
          SegmentedButton<CoverRailAlignment>(
            segments: const [
              ButtonSegment(value: CoverRailAlignment.top, label: Text('Top')),
              ButtonSegment(
                value: CoverRailAlignment.center,
                label: Text('Center'),
              ),
              ButtonSegment(
                value: CoverRailAlignment.bottom,
                label: Text('Bottom'),
              ),
            ],
            selected: {s.tabletRailAlignment},
            onSelectionChanged: (v) =>
                widget.onChanged(s.copyWith(tabletRailAlignment: v.first)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Group the tabs'),
            subtitle: const Text(
                'Side bars and the cover rail open one group at a time'),
            value: s.groupTabs,
            onChanged: (v) => widget.onChanged(s.copyWith(groupTabs: v)),
          ),
          const _Header('Cover rail side'),
          SegmentedButton<RailSide>(
            segments: const [
              ButtonSegment(
                value: RailSide.trailingPhysicalRight,
                label: Text('Right'),
              ),
              ButtonSegment(value: RailSide.physicalLeft, label: Text('Left')),
              ButtonSegment(
                value: RailSide.followTextDirection,
                label: Text('Trailing'),
              ),
            ],
            selected: {s.coverRailSide},
            onSelectionChanged: (v) =>
                widget.onChanged(s.copyWith(coverRailSide: v.first)),
          ),
          const _Header('Cover rail tabs'),
          SegmentedButton<CoverRailAlignment>(
            segments: const [
              ButtonSegment(
                value: CoverRailAlignment.bottom,
                label: Text('Bottom'),
              ),
              ButtonSegment(
                value: CoverRailAlignment.center,
                label: Text('Center'),
              ),
              ButtonSegment(value: CoverRailAlignment.top, label: Text('Top')),
            ],
            selected: {s.coverRailAlignment},
            onSelectionChanged: (v) =>
                widget.onChanged(s.copyWith(coverRailAlignment: v.first)),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Right-to-left'),
            subtitle: const Text('The cover rail stays on the right'),
            value: s.rtl,
            onChanged: (v) => widget.onChanged(s.copyWith(rtl: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lock phones to portrait'),
            value: s.lockPhonesToPortrait,
            onChanged: (v) =>
                widget.onChanged(s.copyWith(lockPhonesToPortrait: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lock opened flip phones like phones'),
            subtitle: const Text('Galaxy Z Flip, Razr'),
            value: s.flipsAsPhones,
            onChanged: (v) => widget.onChanged(s.copyWith(flipsAsPhones: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Phone layout on narrow covers'),
            subtitle:
                const Text('Covers under 380 pt, such as a Galaxy Z Fold'),
            value: s.narrowCoversAsPhones,
            onChanged: (v) =>
                widget.onChanged(s.copyWith(narrowCoversAsPhones: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hide the bar while scrolling'),
            value: s.hideBarOnScroll,
            onChanged: (v) => widget.onChanged(s.copyWith(hideBarOnScroll: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Drawer on wide tablets'),
            subtitle: const Text('From 1200 pt'),
            value: s.drawerOnWideTablets,
            onChanged: (v) =>
                widget.onChanged(s.copyWith(drawerOnWideTablets: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Debug overlay'),
            subtitle: const Text('Form factor, posture, fold and cameras'),
            value: s.debugOverlay,
            onChanged: (v) => widget.onChanged(s.copyWith(debugOverlay: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Disable vertical system bar'),
            subtitle: const Text('iPhone Duo cover display, iOS 27.1+'),
            value: _verticalBarDisabled,
            onChanged: (v) {
              setState(() => _verticalBarDisabled = v);
              FoldPlatform.instance.setVerticalSystemBarDisabled(v);
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}
