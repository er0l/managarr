import 'package:json_annotation/json_annotation.dart';
import 'series.dart';

part 'calendar.g.dart';

@JsonSerializable(explicitToJson: true)
class SonarrCalendar {
  const SonarrCalendar({
    this.id,
    this.seriesId,
    this.episodeFileId,
    this.seasonNumber,
    this.episodeNumber,
    this.title,
    this.airDate,
    this.airDateUtc,
    this.overview,
    this.hasFile,
    this.monitored,
    this.series,
    this.images,
    this.qualityName,
  });

  final int? id;
  final int? seriesId;
  final int? episodeFileId;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? title;
  final String? airDate;
  final DateTime? airDateUtc;
  final String? overview;
  final bool? hasFile;
  final bool? monitored;
  final SonarrSeries? series;
  final List<SonarrImage>? images;

  /// Quality name from the downloaded episode file, e.g. "HDTV-720p".
  final String? qualityName;

  factory SonarrCalendar.fromJson(Map<String, dynamic> json) =>
      _$SonarrCalendarFromJson(json);

  Map<String, dynamic> toJson() => _$SonarrCalendarToJson(this);
}
