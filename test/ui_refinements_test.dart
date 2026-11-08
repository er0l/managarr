import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:managarr/core/database/app_database.dart';
import 'package:managarr/core/database/models/service_type.dart';
import 'package:managarr/core/theme/app_theme.dart';
import 'package:managarr/core/router/router.dart';
import 'package:managarr/features/calendar/providers/calendar_providers.dart';
import 'package:managarr/core/widgets/app_drawer.dart';
import 'package:managarr/features/dashboard/models/health_result.dart';
import 'package:managarr/features/dashboard/providers/health_check_provider.dart';
import 'package:managarr/features/dashboard/widgets/module_launcher.dart';
import 'package:managarr/features/dashboard/widgets/sections/now_playing_section.dart';
import 'package:managarr/features/romm/api/models/romm_platform.dart';
import 'package:managarr/features/romm/api/models/romm_stats.dart';
import 'package:managarr/features/romm/api/models/romm_rom.dart';
import 'package:managarr/features/romm/api/models/romm_search_filters.dart';
import 'package:managarr/features/romm/providers/romm_providers.dart';
import 'package:managarr/features/romm/screens/romm_home_screen.dart';
import 'package:managarr/features/seer/api/models/media_request.dart';
import 'package:managarr/features/seer/providers/seer_providers.dart';
import 'package:managarr/features/seer/screens/seer_requests_screen.dart';
import 'package:managarr/features/seer/widgets/media_request_tile.dart';
import 'package:managarr/features/settings/providers/instances_provider.dart';
import 'package:managarr/features/settings/providers/ui_prefs_provider.dart';
import 'package:managarr/features/settings/screens/settings_screen.dart';
import 'package:managarr/features/tautulli/api/models/tautulli_activity.dart';
import 'package:managarr/features/tautulli/api/models/tautulli_history.dart';
import 'package:managarr/features/tautulli/api/tautulli_api.dart';
import 'package:managarr/features/tautulli/providers/tautulli_providers.dart';
import 'package:managarr/features/tautulli/screens/tautulli_history_screen.dart';
import 'package:managarr/features/tautulli/screens/tautulli_media_detail_screen.dart';

const instance = Instance(
  id: 1,
  name: 'Home server',
  serviceType: 'tautulli',
  baseUrl: 'https://example.invalid',
  apiKey: '',
  enabled: true,
);

class MemorySettings extends AppDatabase {
  MemorySettings() : super.forTesting(NativeDatabase.memory()) {
    addTearDown(close);
  }
  final values = <String, String>{};
  @override
  Future<String?> getSetting(String key) async => values[key];
  @override
  Future<void> setSetting(String key, String value) async {
    values[key] = value;
  }
}

Widget wrap(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(MemorySettings()),
        instancesByServiceProvider.overrideWithValue({}),
        ...overrides,
      ],
      child: MaterialApp(home: child),
    );

void main() {
  test('customizations survive a new provider container', () async {
    final db = MemorySettings();
    final first = ProviderContainer(
      overrides: [dbProvider.overrideWithValue(db)],
    );
    first.read(customizationProvider);
    await first
        .read(customizationProvider.notifier)
        .set('use24HourTime', false);
    await first
        .read(customizationProvider.notifier)
        .set('tautulliRefreshSeconds', 30);
    first.dispose();
    final second = ProviderContainer(
      overrides: [dbProvider.overrideWithValue(db)],
    );
    addTearDown(second.dispose);
    second.read(customizationProvider);
    await Future<void>.delayed(Duration.zero);
    expect(second.read(customizationProvider)['use24HourTime'], isFalse);
    expect(second.read(customizationProvider)['tautulliRefreshSeconds'], 30);
    expect(second.read(customizationProvider)['showUpcoming'], isTrue);
  });

  test('legacy Dark becomes Amoled and new Dark persists separately', () async {
    final db = MemorySettings()..values['theme_mode'] = 'dark';
    final container = ProviderContainer(
      overrides: [dbProvider.overrideWithValue(db)],
    );
    container.read(themeModeProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(themeModeProvider), AppThemeMode.amoled);
    await container.read(themeModeProvider.notifier).setMode(AppThemeMode.dark);
    container.dispose();
    final restored = ProviderContainer(
      overrides: [dbProvider.overrideWithValue(db)],
    );
    addTearDown(restored.dispose);
    restored.read(themeModeProvider);
    await Future<void>.delayed(Duration.zero);
    expect(restored.read(themeModeProvider), AppThemeMode.dark);
    expect(AppThemeMode.system.materialMode, ThemeMode.system);
    expect(AppThemeMode.amoled.materialMode, ThemeMode.dark);
  });

  test(
    'Tautulli history accepts numeric strings and retains episode context',
    () {
      final item = TautulliHistoryItem.fromJson({
        'reference_id': '71',
        'row_id': '72',
        'user_id': '3',
        'rating_key': 200,
        'media_type': 'episode',
        'grandparent_title': 'Severance',
        'title': 'Hello, Ms. Cobel',
        'parent_media_index': '2',
        'media_index': '1',
        'stopped': '1737000000',
        'duration': '3300',
        'percent_complete': '105',
        'grandparent_thumb': '/show/poster',
      });
      expect(item.displayTitle, 'Severance');
      expect(item.subtitle, 'S02E01 · Hello, Ms. Cobel');
      expect(item.percentComplete, 100);
      expect(item.rowId, 72);
      expect(item.poster, '/show/poster');
      expect(item.ratingKey, '200');
    },
  );

  test(
    'metadata and stream requests use the correct identifiers; termination errors surface',
    () async {
      final dio = Dio();
      final commands = <Map<String, dynamic>>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            commands.add(options.queryParameters);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'response':
                      options.queryParameters['cmd'] == 'terminate_session'
                      ? {'result': 'error', 'message': 'Permission denied'}
                      : {
                          'result': 'success',
                          'data': {'title': 'Arrival'},
                        },
                },
              ),
            );
          },
        ),
      );
      final api = TautulliApi(dio, 'https://example.invalid', '');
      expect((await api.getMetadata('42'))['title'], 'Arrival');
      await api.getStreamData(88);
      expect(commands[0]['rating_key'], '42');
      expect(commands[1]['row_id'], 88);
      await expectLater(api.terminateSession('99'), throwsException);
    },
  );

  testWidgets(
    'drawer places Dashboard before services and uses header action icons',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              appBar: AppBar(),
              drawer: const AppDrawer(),
              body: const Text('Dashboard content'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(MemorySettings()),
            instancesByServiceProvider.overrideWithValue({
              ServiceType.tautulli: [instance],
            }),
            healthCheckProvider(instance).overrideWith(
              (_) async =>
                  HealthResult(online: true, checkedAt: DateTime.now()),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Dashboard')).dy,
        lessThan(tester.getTopLeft(find.text('Tautulli')).dy),
      );
      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.text('Search'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    },
  );

  testWidgets('Modules switches from compact tiles to connection details', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Scaffold(body: ModulesScreen()),
        overrides: [
          instancesProvider.overrideWith((_) => Stream.value([instance])),
          healthCheckProvider(instance).overrideWith(
            (_) async => HealthResult(
              online: true,
              checkedAt: DateTime.now(),
              version: '2.14',
              responseMs: 12,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Manage'), findsNothing);
    expect(find.textContaining('Reachable'), findsNothing);
    await tester.tap(find.byTooltip('Switch to List'));
    await tester.pumpAndSettle();
    expect(find.text('Reachable · 12 ms'), findsOneWidget);
    expect(find.text('Remote connection · v2.14'), findsOneWidget);
    expect(find.byTooltip('Switch to Grid'), findsOneWidget);
    expect(find.byTooltip('Switch to List'), findsNothing);
    await tester.tap(find.byTooltip('Switch to Grid'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reachable'), findsNothing);
    expect(find.byTooltip('Switch to List'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seer Requests uses configured columns and exposes list toggle', (
    tester,
  ) async {
    final seer = instance.copyWith(serviceType: 'seer');
    await tester.pumpWidget(
      wrap(
        Scaffold(body: SeerRequestsScreen(instance: seer)),
        overrides: [
          seerRequestsProvider(seer).overrideWith(
            (_) async => [
              SeerMediaRequest(
                id: 1,
                status: 1,
                mediaType: 'movie',
                tmdbId: 1,
                title: 'Arrival',
                overview: '',
                posterPath: '',
                requestedBy: 'Alex',
                createdAt: DateTime(2026),
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final delegate =
        tester.widget<GridView>(find.byType(GridView)).gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
    expect(
      delegate.crossAxisCount,
      4,
    ); // 800dp test tablet: configured 3 + one column.
    await tester.tap(find.byTooltip('Switch to List'));
    await tester.pumpAndSettle();
    expect(find.byType(MediaRequestTile), findsOneWidget);
  });

  testWidgets('ROMM keeps platforms separate and Downloads in More', (
    tester,
  ) async {
    final romm = instance.copyWith(serviceType: 'romm');
    await tester.pumpWidget(
      wrap(
        RommHomeScreen(instance: romm),
        overrides: [
          rommSearchProvider((
            instance: romm,
            searchTerm: 'Mario',
            filters: const RommSearchFilters(),
          )).overrideWith(
            (_) async => [
              const RommRom(
                id: 1,
                name: 'Super Mario World',
                fsName: 'mario.sfc',
                fsSizeBytes: 100,
                platformId: 1,
                platformDisplayName: 'SNES',
              ),
            ],
          ),
          rommStatsProvider(romm).overrideWith((_) async => const RommStats()),
          rommRecentlyAddedProvider(romm).overrideWith((_) async => []),
          rommRecentlyPlayedProvider(romm).overrideWith((_) async => []),
          rommPlatformsProvider(romm).overrideWith(
            (_) async => [
              const RommPlatform(
                id: 1,
                name: 'SNES',
                displayName: 'SNES',
                slug: 'snes',
                romCount: 1,
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SNES'), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Downloads'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Mario');
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to List'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsNothing);
    expect(find.text('Super Mario World'), findsOneWidget);
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(find.text('SNES'), findsWidgets);
    expect(find.widgetWithText(TextField, 'Search platforms'), findsOneWidget);
    await tester.tap(find.byType(NavigationDestination).last);
    await tester.pumpAndSettle();
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('watch history opens a full detail page and media metadata', (
    tester,
  ) async {
    final item = TautulliHistoryItem.fromJson({
      'row_id': 20,
      'reference_id': 21,
      'rating_key': '42',
      'user_id': 3,
      'media_type': 'episode',
      'grandparent_title': 'Severance',
      'title': 'Hello, Ms. Cobel',
      'parent_media_index': 2,
      'media_index': 1,
      'friendly_name': 'Alex',
      'started': 1737000000,
      'stopped': 1737003000,
    });
    await tester.pumpWidget(
      wrap(
        Scaffold(body: TautulliHistoryScreen(instance: instance)),
        overrides: [
          tautulliHistoryProvider(
            instance,
          ).overrideWith((_) async => TautulliHistory(items: [item])),
          tautulliStreamDataProvider((
            instance: instance,
            rowId: 20,
          )).overrideWith((_) async => {'video_codec': 'h264'}),
          tautulliMetadataProvider((
            instance: instance,
            ratingKey: '42',
          )).overrideWith(
            (_) async => {
              'title': 'Hello, Ms. Cobel',
              'media_type': 'episode',
              'grandparent_title': 'Severance',
              'summary': 'Episode synopsis',
            },
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('S02E01'), findsOneWidget);
    expect(find.textContaining('Alex'), findsOneWidget);
    await tester.tap(find.text('Severance'));
    await tester.pumpAndSettle();
    expect(find.text('History details'), findsOneWidget);
    expect(find.byTooltip('User details'), findsOneWidget);
    await tester.tap(find.byTooltip('Media details'));
    await tester.pumpAndSettle();
    expect(find.byType(TautulliMediaDetailScreen), findsOneWidget);
    expect(find.text('Episode synopsis'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Dashboard session opens session details with a clear termination action',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const Scaffold(
            body: SingleChildScrollView(
              child: NowPlayingSection(instances: [instance]),
            ),
          ),
          overrides: [
            tautulliActivityProvider(instance).overrideWith(
              (_) async => const TautulliActivity(
                streamCount: 1,
                sessions: [
                  TautulliSession(
                    sessionKey: '1',
                    ratingKey: '42',
                    title: 'Arrival',
                    friendlyName: 'Alex',
                    progressPercent: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arrival'));
      await tester.pumpAndSettle();
      expect(find.text('Terminate Session'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byTooltip('Media details'), findsOneWidget);
      await tester.tap(find.text('Terminate Session'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Terminate Session'), findsOneWidget);
    },
  );

  testWidgets(
    'root navigation separates Modules and keeps Add at the top of Settings',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          dbProvider.overrideWithValue(MemorySettings()),
          instancesProvider.overrideWith((_) => Stream.value([instance])),
          customizationProvider.overrideWith(SilentDashboardPreferences.new),
          unifiedCalendarProvider.overrideWith(
            (_) => Completer<List<CalendarEntry>>().future,
          ),
          healthCheckProvider(instance).overrideWith(
            (_) async => HealthResult(online: true, checkedAt: DateTime.now()),
          ),
        ],
      );
      final router = container.read(routerProvider);
      addTearDown(router.dispose);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.text('Home server'), findsNothing);
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/modules');
      expect(find.text('Home server'), findsOneWidget);
      await tester.tap(find.byType(NavigationDestination).last);
      await tester.pump(const Duration(milliseconds: 400));
      expect(router.routeInformationProvider.value.uri.path, '/settings');
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Add'), findsOneWidget);
      expect(
        tester.getTopLeft(find.widgetWithText(FilledButton, 'Add')).dy,
        lessThan(tester.getTopLeft(find.text('Appearance')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('appearance provides four theme choices without deeper pages', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const CustomizationScreen(category: 'Appearance')),
    );
    await tester.pumpAndSettle();
    for (final label in ['System', 'Light', 'Dark', 'Amoled']) {
      expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
    }
    await tester.tap(find.widgetWithText(ChoiceChip, 'Amoled'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(CustomizationScreen));
    expect(
      ProviderScope.containerOf(context).read(themeModeProvider),
      AppThemeMode.amoled,
    );
    expect(find.byType(Navigator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class SilentDashboardPreferences extends CustomizationNotifier {
  @override
  Map<String, dynamic> build() => {
    ...CustomizationNotifier.defaults,
    'showNowPlaying': false,
    'showDownloads': false,
    'showUpcoming': false,
    'showRequests': false,
    'showRecentlyAdded': false,
  };
}
