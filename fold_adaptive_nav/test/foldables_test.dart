import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

import 'helpers.dart';

const _tabs = [
  NavDestination(icon: Icons.home, label: 'Home'),
  NavDestination(icon: Icons.search, label: 'Search'),
];

Widget _scaffold() => MaterialApp(
      home: AdaptiveNavScaffold(
        destinations: _tabs,
        currentIndex: 0,
        onSelect: (_) {},
        body: const SizedBox(),
      ),
    );

FormFactor _narrowCoverIsPhone(Size window, FoldState fold, FormFactor suggested) =>
    suggested == FormFactor.cover && window.width < 400 ? FormFactor.phone : suggested;

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => setState(() => count++),
        child: Text('count $count'),
      );
}

void main() {
  group('form factor', () {
    test('coverMinShortestSide sends narrow covers to the phone layout', () {
      const config = FoldAdaptiveConfig(coverMinShortestSide: 380);
      FormFactor of(FoldDevicePreset p) =>
          resolveFormFactor(window: p.size, fold: p.state, config: config);
      expect(of(FoldDevicePreset.galaxyZFoldCover), FormFactor.phone);
      expect(of(FoldDevicePreset.galaxyZFlipCover), FormFactor.phone);
      expect(of(FoldDevicePreset.pixelFoldCover), FormFactor.cover);
      expect(of(FoldDevicePreset.iPhoneDuoCover), FormFactor.cover);
    });

    test('the default keeps every closed foldable on the cover layout', () {
      for (final p in [
        FoldDevicePreset.galaxyZFoldCover,
        FoldDevicePreset.galaxyZFlipCover,
      ]) {
        expect(resolveFormFactor(window: p.size, fold: p.state), FormFactor.cover);
      }
    });

    test('formFactorResolver has the last word', () {
      const config = FoldAdaptiveConfig(formFactorResolver: _narrowCoverIsPhone);
      const zFold = FoldDevicePreset.galaxyZFoldCover;
      const duo = FoldDevicePreset.iPhoneDuoCover;
      expect(
        resolveFormFactor(window: zFold.size, fold: zFold.state, config: config),
        FormFactor.phone,
      );
      expect(
        resolveFormFactor(window: duo.size, fold: duo.state, config: config),
        FormFactor.cover,
      );
      expect(config, const FoldAdaptiveConfig(formFactorResolver: _narrowCoverIsPhone));
    });

    test('every preset gets the layout of its device', () {
      const expected = {
        'Phone': FormFactor.phone,
        'Tablet': FormFactor.tablet,
        'iPhone Duo, closed': FormFactor.cover,
        'iPhone Duo, open': FormFactor.tablet,
        'Pixel Fold, closed': FormFactor.cover,
        'Pixel Fold, open': FormFactor.tablet,
        'Pixel Fold, tabletop': FormFactor.tablet,
        'Galaxy Z Fold, closed': FormFactor.cover,
        'Galaxy Z Fold, open': FormFactor.tablet,
        'Galaxy Z Flip, closed': FormFactor.cover,
        'Galaxy Z Flip, open': FormFactor.phone,
        'Galaxy Z Flip, Flex mode': FormFactor.phone,
      };
      expect(FoldDevicePreset.all.map((p) => p.name), expected.keys);
      for (final p in FoldDevicePreset.all) {
        expect(resolveFormFactor(window: p.size, fold: p.state), expected[p.name],
            reason: p.name);
      }
    });
  });

  group('orientations', () {
    const config = FoldAdaptiveConfig();
    const flip = FoldDevicePreset.galaxyZFlipOpen;

    test('an opened flip phone is locked like a phone', () {
      expect(orientationsFor(flip.state, FormFactor.phone, config),
          [DeviceOrientation.portraitUp]);
      expect(
        orientationsFor(FoldDevicePreset.galaxyZFlipFlex.state, FormFactor.phone, config),
        [DeviceOrientation.portraitUp],
      );
    });

    test('treatOpenedFlipsAsPhones: false lets it turn', () {
      expect(
        orientationsFor(flip.state, FormFactor.phone,
            const FoldAdaptiveConfig(treatOpenedFlipsAsPhones: false)),
        DeviceOrientation.values,
      );
    });

    test('a flip phone follows lockPhonesToPortrait', () {
      expect(
        orientationsFor(flip.state, FormFactor.phone,
            const FoldAdaptiveConfig(lockPhonesToPortrait: false)),
        DeviceOrientation.values,
      );
    });

    test('opened book foldables still turn freely', () {
      expect(
        orientationsFor(FoldDevicePreset.pixelFoldOpen.state, FormFactor.tablet, config),
        DeviceOrientation.values,
      );
    });

    testWidgets('FoldScope locks an opened flip phone to portrait', (tester) async {
      final calls = captureOrientations(tester);
      setWindowSize(tester, flip.size);
      await pumpScoped(tester, const SizedBox(), state: flip.state);
      expect(calls, [
        ['DeviceOrientation.portraitUp'],
      ]);
    });
  });

  group('compact cover rail', () {
    double railWidth(WidgetTester tester) =>
        tester.getSize(find.byType(SideRail)).width;

    testWidgets('narrow covers get a 64 pt rail without labels', (tester) async {
      await tester.pumpWidget(FoldPreview(
        preset: FoldDevicePreset.galaxyZFoldCover,
        child: _scaffold(),
      ));
      expect(railWidth(tester), 64);
      expect(find.text('Home'), findsNothing);
      expect(find.bySemanticsLabel('Home'), findsOneWidget);
    });

    testWidgets('wide covers keep the 88 pt rail with labels', (tester) async {
      await tester.pumpWidget(FoldPreview(
        preset: FoldDevicePreset.pixelFoldCover,
        child: _scaffold(),
      ));
      expect(railWidth(tester), 88);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('compactRailWidth and compactCoverRailBelow are configurable',
        (tester) async {
      await tester.pumpWidget(FoldPreview(
        preset: FoldDevicePreset.pixelFoldCover,
        config: const FoldAdaptiveConfig(compactCoverRailBelow: 500),
        child: MaterialApp(
          theme: ThemeData(
            extensions: const [AdaptiveNavStyle(compactRailWidth: 72)],
          ),
          home: AdaptiveNavScaffold(
            destinations: _tabs,
            currentIndex: 0,
            onSelect: (_) {},
            body: const SizedBox(),
          ),
        ),
      ));
      expect(railWidth(tester), 72);
    });
  });

  group('resolveFoldSplit', () {
    FoldSplit? split(FoldDevicePreset p,
            {FoldSplitMode mode = FoldSplitMode.hingeOrWide, Rect? area}) =>
        resolveFoldSplit(
          area: area ?? Offset.zero & p.size,
          fold: p.state,
          formFactor: resolveFormFactor(window: p.size, fold: p.state),
          mode: mode,
        );

    test('a flat book foldable splits side by side at the fold', () {
      expect(split(FoldDevicePreset.pixelFoldOpen),
          const FoldSplit(axis: Axis.horizontal, start: 420.5, end: 420.5));
    });

    test('a flat flip phone is one screen', () {
      expect(split(FoldDevicePreset.galaxyZFlipOpen), isNull);
    });

    test('half open with the fold across splits top and bottom', () {
      const expected = FoldSplit(axis: Axis.vertical, start: 503, end: 503);
      expect(split(FoldDevicePreset.galaxyZFlipFlex), expected);
      expect(split(FoldDevicePreset.galaxyZFlipFlex, mode: FoldSplitMode.tabletop),
          expected);
      expect(split(FoldDevicePreset.pixelFoldTabletop, mode: FoldSplitMode.tabletop),
          const FoldSplit(axis: Axis.vertical, start: 420.5, end: 420.5));
    });

    test('tabletop mode ignores folds running down', () {
      expect(split(FoldDevicePreset.pixelFoldOpen, mode: FoldSplitMode.tabletop),
          isNull);
    });

    test('wide tablets split at wideSplit only in hingeOrWide', () {
      const wide = FoldDevicePreset(
        name: 'iPad landscape',
        size: Size(1133, 744),
        state: FoldState.unsupported,
      );
      expect(split(wide),
          const FoldSplit(axis: Axis.horizontal, start: 566.5, end: 566.5));
      expect(split(wide, mode: FoldSplitMode.hinge), isNull);
      expect(split(FoldDevicePreset.tablet), isNull); // 744 < 840
    });

    test('the fold is measured from the area', () {
      expect(
        split(FoldDevicePreset.pixelFoldOpen,
            area: const Rect.fromLTWH(100, 0, 741, 701)),
        const FoldSplit(axis: Axis.horizontal, start: 320.5, end: 320.5),
      );
      // An area beside the fold isn't split.
      expect(
        split(FoldDevicePreset.pixelFoldOpen,
            area: const Rect.fromLTWH(500, 0, 341, 701)),
        isNull,
      );
    });

    test('a rotated preset rotates its fold', () {
      final rotated = FoldDevicePreset.pixelFoldOpen.rotated;
      expect(rotated.size, const Size(701, 841));
      expect(rotated.state.regions.single.bounds,
          const Rect.fromLTRB(0, 420.5, 701, 420.5));
      expect(rotated.padding, const EdgeInsets.fromLTRB(24, 0, 16, 0));
    });
  });

  group('FoldSplitView', () {
    Widget app(FoldDevicePreset preset, {TextDirection? direction}) => FoldPreview(
          preset: preset,
          child: MaterialApp(
            builder: (context, child) => direction == null
                ? child!
                : Directionality(textDirection: direction, child: child!),
            home: const Scaffold(
              body: FoldSplitView(
                start: ColoredBox(color: Colors.red, child: _Counter()),
                end: ColoredBox(color: Colors.blue, child: SizedBox.expand()),
              ),
            ),
          ),
        );
    final start = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == Colors.red);
    final end = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == Colors.blue);

    testWidgets('panes meet at the fold of an opened foldable', (tester) async {
      await tester.pumpWidget(app(FoldDevicePreset.pixelFoldOpen));
      await tester.pumpAndSettle();
      expect(tester.getSize(start), const Size(420.5, 701));
      expect(tester.getSize(end), const Size(420.5, 701));
      expect(tester.getTopLeft(start).dx, lessThan(tester.getTopLeft(end).dx));
    });

    testWidgets('a view that is not at the screen edge still splits at the fold',
        (tester) async {
      await tester.pumpWidget(const FoldPreview(
        preset: FoldDevicePreset.pixelFoldOpen,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 100),
              Expanded(
                child: FoldSplitView(
                  mode: FoldSplitMode.hinge,
                  start: ColoredBox(color: Colors.red),
                  end: ColoredBox(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.getSize(start).width, 320.5);
      expect(tester.getSize(end).width, 841 - 420.5);
    });

    testWidgets('start is on the right in RTL', (tester) async {
      await tester.pumpWidget(
          app(FoldDevicePreset.pixelFoldOpen, direction: TextDirection.rtl));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(start).dx, greaterThan(tester.getTopLeft(end).dx));
    });

    testWidgets('one pane on a phone, and start keeps its state on unfolding',
        (tester) async {
      await tester.pumpWidget(app(FoldDevicePreset.pixelFoldCover));
      expect(end, findsNothing);
      await tester.tap(find.text('count 0'));
      await tester.pump();

      await tester.pumpWidget(app(FoldDevicePreset.pixelFoldOpen));
      await tester.pumpAndSettle();
      expect(end, findsOneWidget);
      expect(find.text('count 1'), findsOneWidget);
    });

    testWidgets('TabletopLayout splits at the fold in Flex mode', (tester) async {
      Widget tabletop(FoldDevicePreset preset) => FoldPreview(
            preset: preset,
            child: const Directionality(
              textDirection: TextDirection.ltr,
              child: TabletopLayout(
                top: ColoredBox(color: Colors.red, child: _CounterHost()),
                bottom: ColoredBox(
                  color: Colors.blue,
                  child: SizedBox(height: 100, width: double.infinity),
                ),
              ),
            ),
          );
      await tester.pumpWidget(tabletop(FoldDevicePreset.galaxyZFlipOpen));
      expect(tester.getSize(start).height, 1006 - 100);
      await tester.tap(find.text('count 0'));
      await tester.pump();

      await tester.pumpWidget(tabletop(FoldDevicePreset.galaxyZFlipFlex));
      await tester.pumpAndSettle();
      expect(tester.getSize(start).height, 503);
      expect(tester.getSize(end).height, 503);
      expect(find.text('count 1'), findsOneWidget);
    });
  });

  group('FoldSafeArea', () {
    test('cameraInsets clears each housing from its nearest edge', () {
      const area = Rect.fromLTWH(0, 0, 400, 800);
      expect(cameraInsets(area, [const Rect.fromLTWH(300, 0, 100, 40)]),
          const EdgeInsets.only(top: 40));
      expect(cameraInsets(area, [const Rect.fromLTWH(370, 300, 30, 80)]),
          const EdgeInsets.only(right: 30));
      expect(cameraInsets(area, [const Rect.fromLTWH(0, 900, 50, 50)]),
          EdgeInsets.zero);
    });

    testWidgets('pads the child clear of a camera housing', (tester) async {
      final preset = FoldDevicePreset(
        name: 'cover with a camera',
        size: FoldDevicePreset.iPhoneDuoCover.size,
        state: FoldDevicePreset.iPhoneDuoCover.state.copyWith(regions: const [
          FoldRegion(
            kind: RegionKind.cameraOcclusion,
            bounds: Rect.fromLTWH(380, 0, 86, 52),
            isActive: true,
          ),
        ]),
      );
      final key = GlobalKey();
      await tester.pumpWidget(FoldPreview(
        preset: preset,
        child: FoldSafeArea(child: SizedBox.expand(key: key)),
      ));
      await tester.pumpAndSettle();
      // Only the top edge moves in: 52 pt off the 678 pt height.
      expect(tester.getSize(find.byKey(key)), const Size(466, 678 - 52));
    });
  });

  group('adaptive values', () {
    test('WindowSizeClass follows Material 3', () {
      expect(WindowSizeClass.fromWidth(599), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
      expect(WindowSizeClass.fromWidth(1200), WindowSizeClass.large);
      expect(WindowSizeClass.fromWidth(1600), WindowSizeClass.extraLarge);
      expect(WindowSizeClass.expanded >= WindowSizeClass.medium, isTrue);
    });

    testWidgets('context.adaptive and AdaptiveBuilder pick by form factor',
        (tester) async {
      for (final (preset, columns, text) in [
        (FoldDevicePreset.phone, 2, 'phone'),
        (FoldDevicePreset.pixelFoldCover, 3, 'cover'),
        (FoldDevicePreset.pixelFoldOpen, 4, 'tablet'),
      ]) {
        late int seen;
        await tester.pumpWidget(FoldPreview(
          preset: preset,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(builder: (context) {
              seen = context.adaptive(phone: 2, cover: 3, tablet: 4);
              return AdaptiveBuilder(
                phone: (_) => const Text('phone'),
                cover: (_) => const Text('cover'),
                tablet: (_) => const Text('tablet'),
              );
            }),
          ),
        ));
        expect(seen, columns, reason: preset.name);
        expect(find.text(text), findsOneWidget, reason: preset.name);
      }
    });

    testWidgets('cover and tablet fall back to phone', (tester) async {
      late String seen;
      await tester.pumpWidget(FoldPreview(
        preset: FoldDevicePreset.pixelFoldOpen,
        child: Builder(builder: (context) {
          seen = context.adaptive(phone: 'p');
          return const SizedBox();
        }),
      ));
      expect(seen, 'p');
    });
  });

  testWidgets('FoldListener reports changes, not the first reading',
      (tester) async {
    final postures = <(HingePosture, HingePosture)>[];
    final formFactors = <(FormFactor, FormFactor)>[];
    setWindowSize(tester, const Size(466, 678));
    final controller = await pumpScoped(
      tester,
      FoldListener(
        onPostureChanged: (a, b) => postures.add((a, b)),
        onFormFactorChanged: (a, b) => formFactors.add((a, b)),
        child: const SizedBox(),
      ),
    );
    controller.add(closedFoldable);
    await tester.pump();
    expect(postures, isEmpty);

    setWindowSize(tester, const Size(669, 951));
    controller.add(openFoldable);
    await tester.pump();
    expect(postures, [(HingePosture.closed, HingePosture.fullyOpen)]);
    expect(formFactors, [(FormFactor.cover, FormFactor.tablet)]);
  });

  group('showAdaptiveSheet', () {
    Future<void> open(WidgetTester tester, FoldDevicePreset preset) async {
      await tester.pumpWidget(FoldPreview(
        preset: preset,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAdaptiveSheet<void>(
                context: context,
                builder: (_) => const Text('sheet'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsOneWidget);
    }

    testWidgets('a bottom sheet on phones', (tester) async {
      await open(tester, FoldDevicePreset.phone);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('a dialog on tablets', (tester) async {
      await open(tester, FoldDevicePreset.pixelFoldOpen);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  testWidgets('FoldDebugOverlay labels the state and lets touches through',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(FoldPreview(
      preset: FoldDevicePreset.galaxyZFoldCover,
      child: MaterialApp(
        builder: (context, child) => FoldDebugOverlay(child: child!),
        home: Scaffold(
          body: SizedBox.expand(
            child: GestureDetector(onTap: () => taps++),
          ),
        ),
      ),
    ));
    expect(find.text('cover · closed · 0° · 344×882 · compact'), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.byType(Scaffold)));
    expect(taps, 1);
  });
}

class _CounterHost extends StatelessWidget {
  const _CounterHost();

  @override
  Widget build(BuildContext context) =>
      const Material(child: Center(child: _Counter()));
}
