import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

/// What the settings tab can change, at runtime.
@immutable
class ExampleSettings {
  const ExampleSettings({
    this.tabletNavigation = TabletNavigation.bottomBar,
    this.coverRailSide = RailSide.trailingPhysicalRight,
    this.lockPhonesToPortrait = true,
    this.preview,
    this.rtl = false,
  });

  final TabletNavigation tabletNavigation;
  final RailSide coverRailSide;
  final bool lockPhonesToPortrait;

  /// Pins the form factor, or null to follow the device.
  final FormFactor? preview;
  final bool rtl;

  FoldAdaptiveConfig get config => FoldAdaptiveConfig(
        tabletNavigation: tabletNavigation,
        coverRailSide: coverRailSide,
        lockPhonesToPortrait: lockPhonesToPortrait,
        coverOrientations: const [DeviceOrientation.portraitUp],
      );

  ExampleSettings copyWith({
    TabletNavigation? tabletNavigation,
    RailSide? coverRailSide,
    bool? lockPhonesToPortrait,
    FormFactor? Function()? preview,
    bool? rtl,
  }) =>
      ExampleSettings(
        tabletNavigation: tabletNavigation ?? this.tabletNavigation,
        coverRailSide: coverRailSide ?? this.coverRailSide,
        lockPhonesToPortrait: lockPhonesToPortrait ?? this.lockPhonesToPortrait,
        preview: preview != null ? preview() : this.preview,
        rtl: rtl ?? this.rtl,
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
          const _Header('Tablet navigation'),
          SegmentedButton<TabletNavigation>(
            segments: const [
              ButtonSegment(
                value: TabletNavigation.bottomBar,
                label: Text('Bottom bar'),
              ),
              ButtonSegment(value: TabletNavigation.rail, label: Text('Rail')),
            ],
            selected: {s.tabletNavigation},
            onSelectionChanged: (v) =>
                widget.onChanged(s.copyWith(tabletNavigation: v.first)),
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
