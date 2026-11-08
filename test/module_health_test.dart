import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:managarr/core/database/app_database.dart';
import 'package:managarr/core/database/models/service_type.dart';
import 'package:managarr/core/network/dio_client.dart';
import 'package:managarr/features/dashboard/providers/health_check_provider.dart';
import 'package:managarr/features/rtorrent/api/rtorrent_api.dart';
import 'package:managarr/features/rtorrent/providers/rtorrent_providers.dart';

const instance = Instance(
  id: 1,
  name: 'Server',
  serviceType: 'radarr',
  baseUrl: 'https://remote.invalid',
  localUrl: 'http://local.invalid',
  apiKey: 'test-key',
  enabled: true,
);

void main() {
  for (final type in ServiceType.values.where((t) => !t.usesXmlRpc)) {
    test(
      '${type.displayName} reports a normalized server version and caches it',
      () async {
        final server = instance.copyWith(serviceType: type.name);
        final requests = <RequestOptions>[];
        final dio = transport((request) {
          requests.add(request);
          if (request.path == type.healthPath) {
            return switch (type) {
              ServiceType.tautulli => {
                'response': {'result': 'success', 'data': true},
              },
              ServiceType.romm => <Object>[],
              ServiceType.seer => {'applicationTitle': 'Seer'},
              _ => {'version': ' v1.2.3 ', 'instanceName': 'Media server'},
            };
          }
          return switch (type) {
            ServiceType.seer => {'version': 'v1.2.3'},
            ServiceType.romm => {
              'SYSTEM': {'VERSION': '1.2.3'},
            },
            ServiceType.tautulli => {
              'response': {
                'result': 'success',
                'data': {'tautulli_version': 'v1.2.3'},
              },
            },
            _ => throw StateError('Unexpected version request'),
          };
        });
        final container = ProviderContainer(
          overrides: [dioProvider(server).overrideWithValue(dio)],
        );
        addTearDown(container.dispose);
        final result = await container.read(healthCheckProvider(server).future);
        expect(result.online, true);
        expect(result.version, '1.2.3');
        expect(result.responseMs, isNonNegative);
        final metadataPath = switch (type) {
          ServiceType.seer => '/api/v1/status',
          ServiceType.romm => '/api/heartbeat',
          ServiceType.tautulli => '/api/v2',
          _ => null,
        };
        expect(requests.map((r) => r.path), [
          type.healthPath,
          ?metadataPath,
        ]);
        if (type == ServiceType.tautulli) {
          expect(requests.last.queryParameters, {
            'cmd': 'get_tautulli_info',
            'apikey': 'test-key',
          });
        }
        final count = requests.length;
        await container.read(healthCheckProvider(server).future);
        expect(requests.length, count);
      },
    );
  }

  for (final type in [
    ServiceType.seer,
    ServiceType.romm,
    ServiceType.tautulli,
  ]) {
    for (final denied in [true, false]) {
      test(
        '${type.name}: unavailable version does not mark a healthy service offline ($denied)',
        () async {
          final server = instance.copyWith(serviceType: type.name);
          final dio = transport((request) {
            if (request.path == type.healthPath) {
              return type == ServiceType.tautulli
                  ? {
                      'response': {'result': 'success', 'data': true},
                    }
                  : <Object>[];
            }
            if (denied) {
              throw DioException(
                requestOptions: request,
                response: Response(requestOptions: request, statusCode: 403),
              );
            }
            return {
              'version': <String>[],
              'SYSTEM': 'invalid',
              'response': {'result': 'error'},
            };
          });
          final container = ProviderContainer(
            overrides: [dioProvider(server).overrideWithValue(dio)],
          );
          addTearDown(container.dispose);
          final result = await container.read(
            healthCheckProvider(server).future,
          );
          expect(result.online, true);
          expect(result.version, isNull);
        },
      );
    }
  }

  test('Tautulli authentication errors in an HTTP 200 are offline', () async {
    final server = instance.copyWith(serviceType: 'tautulli');
    final dio = transport(
      (_) => {
        'response': {'result': 'error', 'message': 'Invalid API key'},
      },
    );
    final container = ProviderContainer(
      overrides: [dioProvider(server).overrideWithValue(dio)],
    );
    addTearDown(container.dispose);
    expect(
      (await container.read(healthCheckProvider(server).future)).online,
      false,
    );
  });

  test(
    'switching the effective connection invalidates cached health and version',
    () async {
      final hosts = <String>[];
      final container = ProviderContainer(
        overrides: [
          dioProvider(instance).overrideWith((ref) {
            final local = ref.watch(useLocalUrlProvider(instance.id));
            return transport((request) {
              hosts.add(request.uri.host);
              return {'version': local ? '2.0' : '1.0'};
            }, baseUrl: local ? instance.localUrl! : instance.baseUrl);
          }),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        healthCheckProvider(instance),
        (_, _) {},
      );
      addTearDown(subscription.close);
      expect(
        (await container.read(healthCheckProvider(instance).future)).version,
        '1.0',
      );
      container.read(useLocalUrlProvider(instance.id).notifier).state = true;
      expect(
        (await container.read(healthCheckProvider(instance).future)).version,
        '2.0',
      );
      expect(hosts, ['remote.invalid', 'local.invalid']);
    },
  );

  for (final restricted in [false, true]) {
    test(
      'rTorrent uses client version XML-RPC with optional metadata ($restricted)',
      () async {
        final server = instance.copyWith(serviceType: 'rtorrent');
        final calls = <String>[];
        final dio = transport((request) {
          final body = request.data as String;
          calls.add(body);
          if (body.contains('system.client_version')) {
            if (restricted) {
              return '<methodResponse><fault><value><struct><member><name>faultString</name><value>Restricted</value></member></struct></value></fault></methodResponse>';
            }
            return '<methodResponse><params><param><value><string>0.9.8</string></value></param></params></methodResponse>';
          }
          return '<methodResponse><params><param><value><array><data/></array></value></param></params></methodResponse>';
        });
        final api = RTorrentApi.withClient(dio, '${server.baseUrl}/RPC2');
        final container = ProviderContainer(
          overrides: [rtorrentApiProvider(server).overrideWithValue(api)],
        );
        addTearDown(container.dispose);
        final result = await container.read(healthCheckProvider(server).future);
        expect(result.online, true);
        expect(result.version, restricted ? isNull : '0.9.8');
        expect(calls.length, 2);
        expect(calls.first, contains('system.listMethods'));
        expect(calls.last, contains('system.client_version'));
      },
    );
  }
}

Dio transport(
  Object? Function(RequestOptions) respond, {
  String baseUrl = 'https://remote.invalid',
}) {
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  addTearDown(() => dio.close(force: true));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        try {
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: respond(request),
            ),
          );
        } on DioException catch (error) {
          handler.reject(error);
        }
      },
    ),
  );
  return dio;
}
