import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:managarr/core/database/app_database.dart';
import 'package:managarr/core/database/models/service_type.dart';
import 'package:managarr/features/dashboard/providers/recently_added_provider.dart';
import 'package:managarr/features/dashboard/widgets/sections/downloads_section.dart';
import 'package:managarr/features/dashboard/widgets/sections/recently_added_section.dart';
import 'package:managarr/features/dashboard/widgets/sections/requests_section.dart';
import 'package:managarr/features/romm/api/models/romm_rom.dart';
import 'package:managarr/features/romm/providers/romm_providers.dart';
import 'package:managarr/features/rtorrent/api/models/torrent.dart';
import 'package:managarr/features/rtorrent/providers/rtorrent_providers.dart';
import 'package:managarr/features/seer/api/models/media_request.dart';
import 'package:managarr/features/seer/providers/seer_providers.dart';
import 'package:managarr/features/seer/screens/seer_media_detail_screen.dart';
import 'package:managarr/features/settings/providers/drawer_order_provider.dart';
import 'package:managarr/features/settings/providers/instances_provider.dart';
import 'package:managarr/features/settings/providers/ui_prefs_provider.dart';
import 'package:managarr/features/settings/screens/drawer_settings_screen.dart';
import 'package:managarr/features/tautulli/api/models/tautulli_media_item.dart';
import 'package:managarr/features/tautulli/api/tautulli_api.dart';
import 'package:managarr/features/tautulli/providers/tautulli_providers.dart';
import 'package:managarr/features/tautulli/screens/tautulli_media_detail_screen.dart';

import 'ui_refinements_test.dart' as fixture;

const server = fixture.instance;
const romm = Instance(
  id: 2,
  name: 'Games',
  serviceType: 'romm',
  baseUrl: 'https://games.invalid',
  apiKey: '',
  enabled: true,
);
const offline = Instance(
  id: 3,
  name: 'Offline server',
  serviceType: 'seer',
  baseUrl: 'https://offline.invalid',
  apiKey: '',
  enabled: true,
);

void main() {
  test(
    'recent feed uses Tautulli library filters and handles API errors',
    () async {
      final requested = <String>[];
      var fail = false;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api/v2'));
      addTearDown(() => dio.close(force: true));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requested.add(options.queryParameters['media_type'] as String);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'response': {
                    'result': fail ? 'error' : 'success',
                    'data': {'recently_added': []},
                  },
                },
              ),
            );
          },
        ),
      );
      final api = TautulliApi(dio, server.baseUrl, '');
      final container = ProviderContainer(
        overrides: [tautulliApiProvider(server).overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      for (final kind in [
        RecentKind.movies,
        RecentKind.episodes,
        RecentKind.music,
      ]) {
        await container.read(
          dashboardPlexRecentProvider((instance: server, kind: kind)).future,
        );
      }
      expect(requested, ['movie', 'show', 'artist']);
      fail = true;
      await expectLater(
        api.getRecentlyAdded(mediaType: 'movie'),
        throwsStateError,
      );
    },
  );

  test('drawer order is sanitized, saved, restored, and reset', () async {
    final db = fixture.MemorySettings()
      ..values['drawer_order'] = jsonEncode([
        'romm',
        'retired',
        'romm',
        'seer',
      ]);
    final container = ProviderContainer(
      overrides: [dbProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.read(drawerOrderProvider);
    await Future<void>.delayed(Duration.zero);
    final initial = container.read(drawerOrderProvider);
    expect(initial.take(2), [ServiceType.romm, ServiceType.seer]);
    expect(initial.toSet(), ServiceType.values.toSet());
    expect(initial.length, ServiceType.values.length);
    await container
        .read(drawerOrderProvider.notifier)
        .reorder(0, initial.length);
    final restored = ProviderContainer(
      overrides: [dbProvider.overrideWithValue(db)],
    );
    addTearDown(restored.dispose);
    restored.read(drawerOrderProvider);
    await Future<void>.delayed(Duration.zero);
    expect(restored.read(drawerOrderProvider).last, ServiceType.romm);
    await restored.read(drawerOrderProvider.notifier).reset();
    expect(restored.read(drawerOrderProvider), ServiceType.values);
  });

  testWidgets('drawer handles reorder modules on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(fixture.wrap(const DrawerSettingsScreen()));
    await tester.pumpAndSettle();
    final handles = find.byType(ReorderableDragStartListener);
    await tester.drag(handles.first, const Offset(0, 155));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(DrawerSettingsScreen));
    final order = ProviderScope.containerOf(context).read(drawerOrderProvider);
    expect(order.first, isNot(ServiceType.radarr));
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(
      ProviderScope.containerOf(context).read(drawerOrderProvider),
      ServiceType.values,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('active uploads appear with downloads, idle seeds are excluded', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(
      fixture.wrap(
        const Scaffold(body: DownloadsSection()),
        overrides: [
          instancesByServiceProvider.overrideWithValue({
            ServiceType.rtorrent: [server],
          }),
          rtorrentTorrentsProvider(server).overrideWith(
            (_) async => [
              torrent('Downloading', completed: 50, down: 100, up: 10),
              torrent('Uploading only', completed: 100, up: 200),
              torrent('Idle seed', completed: 100),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Uploading only'), findsOneWidget);
    expect(find.text('Idle seed'), findsNothing);
    expect(find.text('2 active'), findsOneWidget);
    expect(find.textContaining('Uploading · ↑'), findsOneWidget);
    expect(find.textContaining('Downloading · ↓'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'recent requests include approved and available, newest first with offline fallback',
    (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        fixture.wrap(
          const Scaffold(body: RequestsSection(instances: [server, offline])),
          overrides: [
            seerRequestsProvider(server).overrideWith(
              (_) async => [
                request(
                  'Old pending',
                  1,
                  now.subtract(const Duration(days: 2)),
                ),
                request('Approved', 2, now.subtract(const Duration(days: 1))),
                request('Newest available', 5, now),
              ],
            ),
            seerRequestsProvider(
              offline,
            ).overrideWith((_) => Future.error(StateError('offline'))),
            seerMediaDetailProvider((
              instance: server,
              tmdbId: 42,
              mediaType: 'movie',
            )).overrideWith((_) => Completer<Never>().future),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Recent Requests'), findsOneWidget);
      expect(
        find.text('Requests unavailable · Offline server'),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Newest available')).dx,
        lessThan(tester.getTopLeft(find.text('Old pending')).dx),
      );
      expect(find.text('Approved'), findsWidgets);
      await tester.tap(find.text('Newest available'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SeerMediaDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recent additions merge services and filter without hiding healthy data',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.view.resetPhysicalSize());
      final sources = [
        RecentSource(
          server,
          RecentKind.movies,
          AsyncData([
            RecentAddition(
              instance: server,
              kind: RecentKind.movies,
              media: media('Film', 'movie', 100),
            ),
          ]),
        ),
        RecentSource(
          server,
          RecentKind.episodes,
          AsyncData([
            RecentAddition(
              instance: server,
              kind: RecentKind.episodes,
              media: TautulliMediaItem.fromJson({
                'rating_key': '42',
                'title': 'The episode',
                'media_type': 'episode',
                'grandparent_title': 'The show',
                'parent_media_index': '2',
                'media_index': '3',
                'added_at': '200',
              }),
            ),
          ]),
        ),
        RecentSource(
          romm,
          RecentKind.roms,
          AsyncData([
            RecentAddition(
              instance: romm,
              kind: RecentKind.roms,
              rom: RommRom.fromJson({
                'id': 1,
                'name': 'Newest game',
                'created_at': '2026-01-01T00:00:00Z',
                'platform_display_name': 'SNES',
              }),
            ),
          ]),
        ),
        RecentSource(
          server,
          RecentKind.music,
          AsyncError(StateError('offline'), StackTrace.current),
        ),
      ];
      expect(newestAdditions(sources).first.title, 'Newest game');
      await tester.pumpWidget(
        fixture.wrap(
          const Scaffold(
            body: SingleChildScrollView(child: RecentlyAddedSection()),
          ),
          overrides: [
            dashboardRecentSourcesProvider.overrideWithValue(sources),
            tautulliMetadataProvider((
              instance: server,
              ratingKey: '42',
            )).overrideWith(
              (_) async => {'title': 'The episode', 'media_type': 'episode'},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Music unavailable · Home server'), findsOneWidget);
      expect(find.text('Newest game'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'TV Episodes'));
      await tester.pumpAndSettle();
      expect(find.text('Newest game'), findsNothing);
      expect(find.text('The show'), findsOneWidget);
      expect(find.text('S02E03 · The episode'), findsOneWidget);
      await tester.tap(find.text('The show'));
      await tester.pumpAndSettle();
      expect(find.byType(TautulliMediaDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('disabled recently-added categories do not fetch', () async {
    final db = fixture.MemorySettings();
    final container = ProviderContainer(
      overrides: [
        dbProvider.overrideWithValue(db),
        instancesByServiceProvider.overrideWithValue({
          ServiceType.tautulli: [server],
          ServiceType.romm: [romm],
        }),
        rommRecentlyAddedProvider(romm).overrideWith((_) async => []),
      ],
    );
    addTearDown(container.dispose);
    final prefs = container.read(customizationProvider.notifier);
    for (final key in ['recentMovies', 'recentEpisodes', 'recentMusic']) {
      await prefs.set(key, false);
    }
    final subscription = container.listen(
      dashboardRecentSourcesProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final sources = container.read(dashboardRecentSourcesProvider);
    expect(sources.map((s) => s.kind), [RecentKind.roms]);
  });
}

RTorrentTorrent torrent(
  String title, {
  required int completed,
  int down = 0,
  int up = 0,
}) => RTorrentTorrent(
  hash: title,
  name: title,
  size: 100,
  completed: completed,
  downRate: down,
  upRate: up,
  isActive: true,
  state: 1,
  message: '',
  dateAdded: 0,
  dateDone: 0,
  ratio: 1,
  label: '',
);

SeerMediaRequest request(String title, int status, DateTime created) =>
    SeerMediaRequest(
      id: status,
      status: status,
      mediaType: 'movie',
      tmdbId: 42,
      title: title,
      overview: '',
      posterPath: '',
      requestedBy: 'Alex',
      createdAt: created,
    );

TautulliMediaItem media(String title, String type, int added) =>
    TautulliMediaItem(
      ratingKey: title,
      title: title,
      mediaType: type,
      addedAt: added,
    );
