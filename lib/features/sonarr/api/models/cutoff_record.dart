/// A single episode returned from Sonarr's `/api/v3/wanted/cutoff` endpoint.
/// Contains embedded series info so we can show the poster and title.
class SonarrCutoffRecord {
  const SonarrCutoffRecord({
    required this.episodeId,
    required this.seriesId,
    required this.seriesTitle,
    this.seriesPosterUrl,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeTitle,
    this.currentQuality,
  });

  final int episodeId;
  final int seriesId;
  final String seriesTitle;
  final String? seriesPosterUrl;
  final int seasonNumber;
  final int episodeNumber;
  final String episodeTitle;
  final String? currentQuality;

  /// Episode code like "S01E03".
  String get code =>
      'S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}';

  factory SonarrCutoffRecord.fromJson(Map<String, dynamic> json) {
    final series = json['series'] as Map<String, dynamic>? ?? {};
    final images = series['images'] as List? ?? [];
    final posterUrl = images
        .cast<Map>()
        .where((i) => i['coverType'] == 'poster')
        .map((i) => i['remoteUrl'] as String?)
        .firstOrNull;

    final episodeFile = json['episodeFile'] as Map<String, dynamic>?;
    final qualityName =
        (((episodeFile?['quality'] as Map?)?['quality'] as Map?)?['name']
            as String?);

    return SonarrCutoffRecord(
      episodeId: json['id'] as int? ?? 0,
      seriesId: json['seriesId'] as int? ?? 0,
      seriesTitle: series['title'] as String? ?? '',
      seriesPosterUrl: posterUrl,
      seasonNumber: json['seasonNumber'] as int? ?? 0,
      episodeNumber: json['episodeNumber'] as int? ?? 0,
      episodeTitle: json['title'] as String? ?? '',
      currentQuality: qualityName,
    );
  }
}
