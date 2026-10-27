import 'package:flutter/material.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

/// Content that adapts with `context.adaptive`, [AdaptiveBuilder] and
/// `context.windowSizeClass`, and a sheet that becomes a dialog on tablets.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizeClass = context.windowSizeClass;
    final columns = sizeClass >= WindowSizeClass.expanded
        ? 6
        : context.adaptive(phone: 2, cover: 3, tablet: 4);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gallery', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    Chip(label: Text('${sizeClass.name} window')),
                    Chip(label: Text('$columns columns')),
                  ]),
                  const SizedBox(height: 8),
                  AdaptiveBuilder(
                    phone: (_) => const Text('Phone: two columns.'),
                    cover: (_) =>
                        const Text('Cover: three columns, the rail beside.'),
                    tablet: (_) => const Text(
                        'Tablet: four columns, six from 840 pt wide.'),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverGrid.count(
              crossAxisCount: columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (var i = 0; i < 30; i++) _Tile(index: i),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final color = Colors.primaries[index % Colors.primaries.length];
    return Material(
      color: color.shade200,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showAdaptiveSheet<void>(
          context: context,
          builder: (context) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: color.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Photo ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text('A bottom sheet on phones, a dialog on tablets.'),
              ],
            ),
          ),
        ),
        child: Center(
          child: Text('${index + 1}',
              style: TextStyle(color: color.shade900, fontSize: 20)),
        ),
      ),
    );
  }
}
