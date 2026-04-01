import 'package:json_annotation/json_annotation.dart';

part 'root_folder.g.dart';

@JsonSerializable()
class SonarrRootFolder {
  const SonarrRootFolder({
    required this.id,
    required this.path,
    this.freeSpace,
  });

  final int id;
  final String path;
  final int? freeSpace;

  factory SonarrRootFolder.fromJson(Map<String, dynamic> json) =>
      _$SonarrRootFolderFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrRootFolderToJson(this);
}
