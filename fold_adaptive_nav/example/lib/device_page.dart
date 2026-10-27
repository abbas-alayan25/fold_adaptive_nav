import 'package:flutter/material.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

/// Shows what the package knows about the device, live.
class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formFactor = context.formFactor;
    final state = FoldMediaQuery.stateOf(context);
    final size = MediaQuery.sizeOf(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Text('This device', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(switch (formFactor) {
                FormFactor.phone => Icons.smartphone,
                FormFactor.cover => Icons.devices_fold,
                FormFactor.tablet => Icons.tablet_mac,
              }),
              title: Text(formFactor.name, style: theme.textTheme.titleLarge),
              subtitle: Text(
                '${size.width.round()} × ${size.height.round()} pt',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _Row('Foldable', state.isFoldable ? 'yes' : 'no'),
                _Row('Posture', state.posture.name),
                const _HingeAngleRow(),
                _Row(
                  'Size classes',
                  '${state.horizontalSizeClass.name} × '
                      '${state.verticalSizeClass.name}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ListTile(title: Text('Reserved regions')),
                if (state.regions.isEmpty)
                  const ListTile(dense: true, title: Text('None reported')),
                for (final r in state.regions)
                  ListTile(
                    dense: true,
                    leading: Icon(r.kind == RegionKind.fold
                        ? Icons.vertical_split
                        : Icons.camera_alt_outlined),
                    title: Text('${r.kind.name}${r.isActive ? '' : ' (inactive)'}'),
                    subtitle: Text(
                      '${r.bounds.left.round()}, ${r.bounds.top.round()} · '
                      '${r.bounds.width.round()} × ${r.bounds.height.round()}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

/// The raw angle stream rebuilds only this row, once per frame at most.
class _HingeAngleRow extends StatelessWidget {
  const _HingeAngleRow();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: FoldPlatform.instance.hingeAngle,
      builder: (context, snapshot) => _Row(
        'Hinge angle',
        snapshot.hasData ? '${snapshot.data!.round()}°' : '—',
      ),
    );
  }
}
