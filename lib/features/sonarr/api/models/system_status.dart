import 'package:json_annotation/json_annotation.dart';

part 'system_status.g.dart';

@JsonSerializable()
class SonarrSystemStatus {
  const SonarrSystemStatus({
    required this.version,
    this.osVersion,
    this.isLinux,
  });

  final String version;
  final String? osVersion;
  final bool? isLinux;

  factory SonarrSystemStatus.fromJson(Map<String, dynamic> json) =>
      _$SonarrSystemStatusFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrSystemStatusToJson(this);
}
