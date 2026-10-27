# fold_adaptive_nav_platform_interface

The common platform interface for [`fold_adaptive_nav`](https://pub.dev/packages/fold_adaptive_nav):
the `FoldState` data model, the `FoldStateCodec` wire format and the
`FoldPlatform` base class.

App code should depend on `fold_adaptive_nav`, not this package.

## Writing an implementation

Extend `FoldPlatform` (or `MethodChannelFold` to reuse the channels) and set
`FoldPlatform.instance` from your package's `registerWith`.

Channels: `fold_adaptive_nav/methods` (`snapshot`,
`setVerticalSystemBarDisabled`), `fold_adaptive_nav/state` (full state maps)
and `fold_adaptive_nav/angle` (doubles, at most one per frame). Every state
map carries `"v": 1`. Decoding ignores unknown keys and maps unknown enum
strings to `unknown`/`unspecified`.
