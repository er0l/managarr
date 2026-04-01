import 'package:json_annotation/json_annotation.dart';

part 'system_status.g.dart';

@JsonSerializable()
class RadarrSystemStatus {
  const RadarrSystemStatus({
    required this.version,
    this.startupPath,
    this.appData,
    this.osVersion,
    this.runtimeVersion,
    this.isDebug,
    this.isLinux,
    this.isOsx,
    this.isWindows,
  });

  final String version;
  final String? startupPath;
  final String? appData;
  final String? osVersion;
  final String? runtimeVersion;
  final bool? isDebug;
  final bool? isLinux;
  final bool? isOsx;
  final bool? isWindows;

  factory RadarrSystemStatus.fromJson(Map<String, dynamic> json) =>
      _$RadarrSystemStatusFromJson(json);

  Map<String, dynamic> toJson() => _$RadarrSystemStatusToJson(this);
}
