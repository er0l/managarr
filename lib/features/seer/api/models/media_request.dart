import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SeerMediaRequest {
  final int id;
  final int status; // 1=pending, 2=approved, 3=declined, 4=partially available, 5=available
  final String mediaType; // movie | tv
  final int tmdbId;
  String title;
  String overview;
  String posterPath;
  final String requestedBy;
  final DateTime createdAt;

  SeerMediaRequest({
    required this.id,
    required this.status,
    required this.mediaType,
    required this.tmdbId,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.requestedBy,
    required this.createdAt,
  });

  factory SeerMediaRequest.fromJson(Map<String, dynamic> json) {
    return SeerMediaRequest(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      status: int.tryParse(json['status']?.toString() ?? '') ?? 0,
      mediaType: json['media']?['mediaType'] ?? json['type'] ?? '',
      tmdbId: json['media']?['tmdbId'] ?? 0,
      title: _extractTitle(json),
      overview: _extractOverview(json),
      posterPath: json['media']?['posterPath'] ?? '',
      requestedBy: json['requestedBy']?['displayName'] ?? 'Unknown',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get statusText => switch (status) {
        1 => 'Pending',
        2 => 'Approved',
        3 => 'Declined',
        4 => 'Partially Available',
        5 => 'Available',
        _ => 'Unknown',
      };

  Color get statusColor => switch (status) {
        1 => AppColors.statusWarning,
        2 => AppColors.statusOnline,
        3 => AppColors.statusOffline,
        4 => AppColors.statusOnline,
        5 => AppColors.statusOnline,
        _ => AppColors.statusUnknown,
      };

  static String _extractTitle(Map<String, dynamic> json) {
    if (json['title'] != null && json['title'].toString().isNotEmpty) return json['title'];
    if (json['name'] != null && json['name'].toString().isNotEmpty) return json['name'];
    if (json['media'] != null) {
      final movie = json['media']['movie'];
      final tv = json['media']['tv'];
      if (movie?['title'] != null && movie['title'].toString().isNotEmpty) return movie['title'];
      if (tv?['name'] != null && tv['name'].toString().isNotEmpty) return tv['name'];
      if (json['media']['title'] != null && json['media']['title'].toString().isNotEmpty) {
        return json['media']['title'];
      }
      if (json['media']['name'] != null && json['media']['name'].toString().isNotEmpty) {
        return json['media']['name'];
      }
      final tmdbId = json['media']['tmdbId'];
      if (tmdbId != null) {
        final type = json['media']['mediaType'] == 'movie' ? 'Movie' : 'TV Show';
        return '$type $tmdbId';
      }
    }
    return 'Request ${json['id'] ?? 'Unknown'}';
  }

  static String _extractOverview(Map<String, dynamic> json) {
    if (json['overview'] != null && json['overview'].toString().isNotEmpty) return json['overview'];
    if (json['media'] != null) {
      if (json['media']['overview'] != null && json['media']['overview'].toString().isNotEmpty) {
        return json['media']['overview'];
      }
      final movie = json['media']['movie'];
      if (movie?['overview'] != null && movie['overview'].toString().isNotEmpty) return movie['overview'];
      final tv = json['media']['tv'];
      if (tv?['overview'] != null && tv['overview'].toString().isNotEmpty) return tv['overview'];
    }
    return '';
  }
}
