import 'package:json_annotation/json_annotation.dart';

part 'root_folder.g.dart';

@JsonSerializable()
class LidarrRootFolder {
  const LidarrRootFolder({
    required this.id,
    required this.path,
    this.freeSpace,
  });

  final int id;
  final String path;
  final int? freeSpace;

  factory LidarrRootFolder.fromJson(Map<String, dynamic> json) =>
      _$LidarrRootFolderFromJson(json);

  Map<String, dynamic> toJson() => _$LidarrRootFolderToJson(this);
}
