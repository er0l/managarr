import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:managarr/core/database/app_database.dart';
import 'package:managarr/core/database/models/service_type.dart';
import 'package:managarr/core/network/dio_client.dart';
import 'package:managarr/core/widgets/module_app_bar.dart';
import 'package:managarr/core/widgets/service_detail_shell.dart';
import 'package:managarr/features/settings/providers/instances_provider.dart';

const _instance = Instance(
  id: 1,
  name: 'Home server',
  serviceType: 'radarr',
  baseUrl: 'https://example.invalid',
  apiKey: '',
  enabled: true,
  localUrl: 'http://example.invalid',
);

Widget _detail(BuildContext context, {bool nested = false}) => Scaffold(
  appBar: ModuleAppBar(title: Text(nested ? 'Nested detail' : 'Item details')),
  body: TextButton(
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _detail(context, nested: true),
      ),
    ),
    child: const Text('Open nested detail'),
  ),
);

Widget _shell({VoidCallback? onSecondMount, ValueChanged<String>? onMore}) =>
    ServiceDetailShell(
      instance: _instance,
      serviceName: 'Radarr',
      sections: [
        ServiceSection(
          label: 'Library',
          icon: Icons.video_library_outlined,
          body: Builder(
            builder: (context) => Column(
              children: [
                const TextField(key: Key('library-search')),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => _detail(context),
                    ),
                  ),
                  child: const Text('Open item'),
                ),
              ],
            ),
          ),
        ),
        ServiceSection(
          label: 'Upcoming',
          icon: Icons.calendar_month,
          body: _MountProbe(onMount: onSecondMount),
        ),
      ],
      moreItems: const [
        PopupMenuItem(
          value: 'history',
          child: ListTile(leading: Icon(Icons.history), title: Text('History')),
        ),
      ],
      onMoreSelected: onMore,
    );

Widget _providers(Widget child) => ProviderScope(
  overrides: [instancesByServiceProvider.overrideWithValue({})],
  child: child,
);

GoRouter _router({String initial = '/', bool directModule = false}) => GoRouter(
  initialLocation: directModule ? '/module' : initial,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const Scaffold(body: Text('Dashboard modules')),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => Scaffold(
        body: TextButton(
          onPressed: () => context.push('/module'),
          child: const Text('Open module'),
        ),
      ),
    ),
    GoRoute(path: '/module', builder: (context, state) => _shell()),
  ],
);

void main() {
  testWidgets(
    'sections mount lazily and preserve search; More actions still work',
    (tester) async {
      var mounts = 0;
      String? action;
      await tester.pumpWidget(
        _providers(
          MaterialApp(
            home: _shell(
              onSecondMount: () => mounts++,
              onMore: (value) => action = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(mounts, 0);
      await tester.enterText(
        find.byKey(const Key('library-search')),
        'Arrival',
      );
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(mounts, 1);
      await tester.tap(find.byType(NavigationDestination).at(0));
      await tester.pumpAndSettle();
      expect(find.text('Arrival'), findsOneWidget);
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(mounts, 1);
      await tester.tap(find.byType(NavigationDestination).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('History'));
      expect(action, 'history');
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ServiceDetailShell));
      expect(
        ProviderScope.containerOf(context).read(useLocalUrlProvider(1)),
        isTrue,
      );
    },
  );

  for (final direct in [false, true]) {
    testWidgets(
      'Home clears nested routes ${direct ? 'from direct module' : 'when launched from Calendar'}',
      (tester) async {
        final router = _router(initial: '/calendar', directModule: direct);
        addTearDown(router.dispose);
        await tester.pumpWidget(
          _providers(MaterialApp.router(routerConfig: router)),
        );
        await tester.pumpAndSettle();
        if (!direct) {
          await tester.tap(find.text('Open module'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Open item'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open nested detail'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(find.text('Dashboard modules'), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, '/');
        expect(find.text('Nested detail'), findsNothing);
        expect(router.canPop(), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Back returns one screen and preserves the library', (
    tester,
  ) async {
    final router = _router(directModule: true);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _providers(MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('library-search')), 'Dune');
    await tester.tap(find.text('Open item'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ModuleBackButton));
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/module');
  });

  testWidgets('Back falls back to Dashboard on a standalone detail route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Dashboard modules')),
        ),
        GoRoute(path: '/detail', builder: (context, _) => _detail(context)),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _providers(MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ModuleBackButton));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard modules'), findsOneWidget);
  });

  for (final type in ServiceType.values) {
    testWidgets(
      '${type.displayName} chrome fits a narrow phone in both themes',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            _providers(
              MaterialApp(
                theme: ThemeData(brightness: brightness, useMaterial3: true),
                home: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(320, 740),
                    textScaler: TextScaler.linear(1.3),
                  ),
                  child: ServiceDetailShell(
                    instance: _instance.copyWith(serviceType: type.name),
                    serviceName: type.displayName,
                    sections: const [
                      ServiceSection(
                        label: 'Library',
                        icon: Icons.library_books,
                        body: SizedBox(),
                      ),
                      ServiceSection(
                        label: 'Upcoming',
                        icon: Icons.calendar_month,
                        body: SizedBox(),
                      ),
                      ServiceSection(
                        label: 'Missing',
                        icon: Icons.error_outline,
                        body: SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Home'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}

class _MountProbe extends StatefulWidget {
  const _MountProbe({this.onMount});
  final VoidCallback? onMount;
  @override
  State<_MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount?.call();
  }

  @override
  Widget build(BuildContext context) => const Text('Upcoming content');
}
