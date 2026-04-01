class HealthResult {
  const HealthResult({
    required this.online,
    required this.checkedAt,
    this.version,
    this.instanceName,
    this.responseMs,
  });

  final bool online;
  final DateTime checkedAt;
  final String? version;
  final String? instanceName;
  final int? responseMs;

  factory HealthResult.offline(DateTime checkedAt) =>
      HealthResult(online: false, checkedAt: checkedAt);
}
