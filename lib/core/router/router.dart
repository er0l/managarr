import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/providers/calendar_providers.dart';
import '../../features/calendar/screens/unified_calendar_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/seer/screens/seer_home_screen.dart';
import '../../features/prowlarr/screens/prowlarr_home_screen.dart';
import '../../features/radarr/screens/radarr_home_screen.dart';
import '../../features/radarr/screens/radarr_movie_detail_screen.dart';
import '../../features/rtorrent/screens/rtorrent_home_screen.dart';
import '../../features/sabnzbd/screens/sabnzbd_home_screen.dart';
import '../../features/services/screens/services_screen.dart';
import '../../features/settings/screens/add_edit_instance_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/repositories/instance_repository.dart';
import '../../features/sonarr/screens/sonarr_home_screen.dart';
import '../../features/sonarr/screens/sonarr_series_detail_screen.dart';
import '../../features/lidarr/screens/lidarr_home_screen.dart';
import '../../features/nzbget/screens/nzbget_home_screen.dart';
import '../../features/tautulli/screens/tautulli_home_screen.dart';
import '../../features/radarr/providers/radarr_providers.dart';
import '../../features/sonarr/providers/sonarr_providers.dart';
import '../database/app_database.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../../features/widget/widget_update_service.dart';

// ---------------------------------------------------------------------------
// Loaders — fetch Instance from DB before pushing module screens
// ---------------------------------------------------------------------------

class _RadarrLoader extends ConsumerWidget {
  const _RadarrLoader({required this.instanceId});
  final int instanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(instanceRepositoryProvider);
    return FutureBuilder<Instance?>(
      future: repo.getById(instanceId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final instance = snap.data;
        if (instance == null) {
          return const Scaffold(
              body: Center(child: Text('Instance not found')));
        }
        return RadarrHomeScreen(instance: instance);
      },
    );
  }
}

class _SonarrLoader extends ConsumerWidget {
  const _SonarrLoader({required this.instanceId});
  final int instanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(instanceRepositoryProvider);
    return FutureBuilder<Instance?>(
      future: repo.getById(instanceId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final instance = snap.data;
        if (instance == null) {
          return const Scaffold(
              body: Center(child: Text('Instance not found')));
        }
        return SonarrHomeScreen(instance: instance);
      },
    );
  }
}

class _LidarrLoader extends ConsumerWidget {
  const _LidarrLoader({required this.instanceId});
  final int instanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(instanceRepositoryProvider);
    return FutureBuilder<Instance?>(
      future: repo.getById(instanceId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final instance = snap.data;
        if (instance == null) {
          return const Scaffold(
              body: Center(child: Text('Instance not found')));
        }
        return LidarrHomeScreen(instance: instance);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shell scaffold
// ---------------------------------------------------------------------------

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  List<Widget> _actionsForTab(BuildContext context, int index) => [];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep home-screen widget data fresh whenever the calendar data reloads.
    // ref.watch keeps the autoDispose provider alive and rebuilds _AppShell
    // when data arrives; the side-effect runs on every resolved value.
    final calendarAsync = ref.watch(unifiedCalendarProvider);
    calendarAsync.whenData(WidgetUpdateService.updateFromEntries);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        elevation: 0,
        title: const Text(
          'managarr',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        actions: [
          ..._actionsForTab(context, navigationShell.currentIndex),
          if (navigationShell.currentIndex == 2)
            IconButton(
              icon: Icon(
                ref.watch(calendarViewModeProvider)
                    ? Icons.view_list_outlined
                    : Icons.calendar_view_month_outlined,
                color: AppColors.textOnPrimary,
              ),
              tooltip: ref.watch(calendarViewModeProvider)
                  ? 'List view'
                  : 'Month view',
              onPressed: () => ref
                  .read(calendarViewModeProvider.notifier)
                  .state = !ref.read(calendarViewModeProvider),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ── Bottom-nav shell ───────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          // Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Services
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/services',
                builder: (context, state) => const ServicesScreen(),
              ),
            ],
          ),
          // Calendar
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const UnifiedCalendarScreen(),
              ),
            ],
          ),
          // Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'add-instance',
                    builder: (context, state) => const AddEditInstanceScreen(),
                  ),
                  GoRoute(
                    path: 'edit-instance/:id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return _EditInstanceLoader(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Module routes (outside shell — full-screen) ────────────────────
      GoRoute(
        path: '/radarr/:instanceId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['instanceId']!);
          return _RadarrLoader(instanceId: id);
        },
        routes: [
          GoRoute(
            path: 'movie/:movieId',
            builder: (context, state) => _RadarrMovieDeepLink(
              instanceId: int.parse(state.pathParameters['instanceId']!),
              movieId: int.parse(state.pathParameters['movieId']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/sonarr/:instanceId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['instanceId']!);
          return _SonarrLoader(instanceId: id);
        },
        routes: [
          GoRoute(
            path: 'series/:seriesId',
            builder: (context, state) => _SonarrSeriesDeepLink(
              instanceId: int.parse(state.pathParameters['instanceId']!),
              seriesId: int.parse(state.pathParameters['seriesId']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/seer/:instanceId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['instanceId']!);
          return _SeerLoader(instanceId: id);
        },
      ),
      GoRoute(
        path: '/rtorrent/:instanceId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['instanceId']!);
          return _RTorrentLoader(instanceId: id);
        },
      ),
      GoRoute(
        path: '/sabnzbd/:instanceId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['instanceId']!);
          return _SabnzbdLoader(instanceId: id);
        },
      ),
      GoRoute(
        path: '/prowlarr/:instanceId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['instanceId']!);
          return _ProwlarrLoader(instanceId: id);
        },
      ),
      GoRoute(
        path: '/nzbget/:instanceId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['instanceId']!);
          return _NzbgetLoader(instanceId: id);
        },
      ),
      GoRoute(
        path: '/lidarr/:instanceId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['instanceId']!);
          return _LidarrLoader(instanceId: id);
        },
      ),
      GoRoute(
        path: '/tautulli/:instanceId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['instanceId']!);
          return _TautulliLoader(instanceId: id);
        },
      ),

    ],
  );
});

// ---------------------------------------------------------------------------
// Edit instance loader
// ---------------------------------------------------------------------------

class _EditInstanceLoader extends ConsumerWidget {
  const _EditInstanceLoader({required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(instanceRepositoryProvider);
    return FutureBuilder(
      future: repo.getById(id),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final instance = snap.data;
        if (instance == null) {
          return const Scaffold(
            body: Center(child: Text('Instance not found')),
          );
        }
        return AddEditInstanceScreen(existingInstance: instance);
      },
    );
  }
}

class _SeerLoader extends ConsumerWidget {
  const _SeerLoader({required this.instanceId});
  final int instanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(instanceRepositoryProvider);
    return FutureBuilder<Instance?>(
      future: repo.getById(instanceId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final instance = snap.data;
        if (instance == null) {
          return const Scaffold(body: Center(child: Text('Instance not found')));
        }
        return SeerHomeScreen(instance: instance);
      },
    );
  }
}

class _RTorrentLoader extends ConsumerWidget {
  const _RTorrentLoader({required this.instanceId});
  final int instanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(instanceRepositoryProvider);
    return FutureBuilder<Instance?>(
      future: repo.getById(instanceId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final instance = snap.data;
        if (instance == null) {
          return const Scaffold(body: Center(child: Text('Instance not found')));
        }
        return RTorrentHomeScreen(instance: instance);
      },
    );
  }
}

class _SabnzbdLoader extends ConsumerWidget {
  const _SabnzbdLoader({required this.instanceId});
  final int instanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(instanceRepositoryProvider);
    return FutureBuilder<Instance?>(
      future: repo.getById(instanceId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final instance = snap.data;
        if (instance == null) {
          return const Scaffold(body: Center(child: Text('Instance not found')));
        }
        return SabnzbdHomeScreen(instance: instance);
      },
    );
  }
}

class _ProwlarrLoader extends ConsumerWidget {
  const _ProwlarrLoader({required this.instanceId});
  final int instanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(instanceRepositoryProvider);
    return FutureBuilder<Instance?>(
      future: repo.getById(instanceId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final instance = snap.data;
        if (instance == null) {
          return const Scaffold(body: Center(child: Text('Instance not found')));
        }
        return ProwlarrHomeScreen(instance: instance);
      },
    );
  }
}

class _NzbgetLoader extends ConsumerWidget {
  const _NzbgetLoader({required this.instanceId});
  final int instanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(instanceRepositoryProvider);
    return FutureBuilder<Instance?>(
      future: repo.getById(instanceId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final instance = snap.data;
        if (instance == null) {
          return const Scaffold(body: Center(child: Text('Instance not found')));
        }
        return NzbgetHomeScreen(instance: instance);
      },
    );
  }
}

class _TautulliLoader extends ConsumerWidget {
  const _TautulliLoader({required this.instanceId});
  final int instanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(instanceRepositoryProvider);
    return FutureBuilder<Instance?>(
      future: repo.getById(instanceId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final instance = snap.data;
        if (instance == null) {
          return const Scaffold(body: Center(child: Text('Instance not found')));
        }
        return TautulliHomeScreen(instance: instance);
      },
    );
  }
}

// Deep-link loaders for widget item taps.

class _RadarrMovieDeepLink extends ConsumerWidget {
  const _RadarrMovieDeepLink({required this.instanceId, required this.movieId});
  final int instanceId;
  final int movieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(instanceRepositoryProvider);
    return FutureBuilder<Instance?>(
      future: repo.getById(instanceId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final instance = snap.data;
        if (instance == null) {
          return const Scaffold(body: Center(child: Text('Instance not found')));
        }
        final api = ref.read(radarrApiProvider(instance));
        return FutureBuilder(
          future: api.getMovieById(movieId),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError || snap.data == null) {
              return const Scaffold(body: Center(child: Text('Movie not found')));
            }
            return RadarrMovieDetailScreen(movie: snap.data!, instance: instance);
          },
        );
      },
    );
  }
}

class _SonarrSeriesDeepLink extends ConsumerWidget {
  const _SonarrSeriesDeepLink({required this.instanceId, required this.seriesId});
  final int instanceId;
  final int seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(instanceRepositoryProvider);
    return FutureBuilder<Instance?>(
      future: repo.getById(instanceId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final instance = snap.data;
        if (instance == null) {
          return const Scaffold(body: Center(child: Text('Instance not found')));
        }
        final api = ref.read(sonarrApiProvider(instance));
        return FutureBuilder(
          future: api.getSeriesById(seriesId),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError || snap.data == null) {
              return const Scaffold(body: Center(child: Text('Series not found')));
            }
            return SonarrSeriesDetailScreen(series: snap.data!, instance: instance);
          },
        );
      },
    );
  }
}
