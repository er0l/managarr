import 'package:drift/drift.dart';

/// Drift table definition for service instances.
class Instances extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// Stored as the enum name string (e.g. 'radarr', 'sonarr').
  TextColumn get serviceType => text()();

  TextColumn get baseUrl => text()();
  TextColumn get apiKey => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Optional LAN URL used when the device is on the home network.
  /// When non-null the app probes this URL first; falls back to [baseUrl].
  TextColumn get localUrl => text().nullable()();

  /// Optional HTTP Basic Auth credentials for a reverse proxy that sits
  /// in front of this service when accessed externally. When set, every
  /// outgoing request includes an `Authorization: Basic` header so the
  /// proxy lets it through before the service validates its own API key.
  TextColumn get proxyUsername => text().nullable()();
  TextColumn get proxyPassword => text().nullable()();
}
