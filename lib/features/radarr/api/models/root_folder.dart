import 'package:json_annotation/json_annotation.dart';

part 'root_folder.g.dart';

@JsonSerializable()
class RadarrRootFolder {
  const RadarrRootFolder({
    required this.id,
    required this.path,
    this.freeSpace,
  });

  final int id;
  final String path;
  final int? freeSpace;

  factory RadarrRootFolder.fromJson(Map<String, dynamic> json) =>
      _$RadarrRootFolderFromJson(json);

  Map<String, dynamic> toJson() => _$RadarrRootFolderToJson(this);
}
