import 'package:flutter/material.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

/// [TabletopLayout]: stand a foldable half open with the fold across (a
/// Pixel Fold held upright, a Z Flip in Flex mode) and the "video" moves
/// above the fold, the controls below. Playback carries on through it.
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  late final _playback = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  );

  @override
  void dispose() {
    _playback.dispose();
    super.dispose();
  }

  void _toggle() => setState(() {
        _playback.isAnimating ? _playback.stop() : _playback.repeat();
      });

  @override
  Widget build(BuildContext context) {
    // Keeps the picture clear of camera housings the platform reports.
    return FoldSafeArea(
      bottom: false,
      child: TabletopLayout(
        top: _Screen(playback: _playback, onTap: _toggle),
        bottom: _Controls(playback: _playback, onToggle: _toggle),
      ),
    );
  }
}

class _Screen extends StatelessWidget {
  const _Screen({required this.playback, required this.onTap});

  final AnimationController playback;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: playback,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(playback.value * 6.283),
              colors: [scheme.primary, scheme.tertiary, scheme.secondary],
            ),
          ),
          child: Center(
            child: Icon(
              playback.isAnimating ? Icons.pause_circle : Icons.play_circle,
              size: 72,
              color: scheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.playback, required this.onToggle});

  final AnimationController playback;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabletop = TabletopLayout.isTabletop(FoldMediaQuery.stateOf(context));
    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        // Room for the bottom bar when it floats over the controls.
        padding: EdgeInsets.fromLTRB(16, 12, 16, tabletop ? 12 : 104),
        child: AnimatedBuilder(
          animation: playback,
          builder: (context, _) {
            final seconds = (playback.value * 90).round();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tabletop
                      ? 'Tabletop: controls below the fold'
                      : 'Stand the device half open with the fold across',
                  style: theme.textTheme.titleSmall,
                ),
                Slider(
                  value: playback.value,
                  onChanged: (v) => playback.value = v,
                ),
                Row(
                  children: [
                    Text('0:${seconds.toString().padLeft(2, '0')} / 1:30'),
                    const Spacer(),
                    IconButton.filled(
                      tooltip: playback.isAnimating ? 'Pause' : 'Play',
                      onPressed: onToggle,
                      icon: Icon(
                        playback.isAnimating ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
