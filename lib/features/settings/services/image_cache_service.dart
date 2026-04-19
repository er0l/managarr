import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// Stats snapshot for the Flutter in-memory image cache.
class InMemoryCacheInfo {
  const InMemoryCacheInfo({
    required this.sizeBytes,
    required this.imageCount,
    required this.maxSizeBytes,
  });

  final int sizeBytes;
  final int imageCount;
  final int maxSizeBytes;

  bool get isEmpty => imageCount == 0;
}

abstract final class ImageCacheService {
  // ── In-memory Flutter ImageCache ─────────────────────────────────────────

  /// Reads the current state of Flutter's in-memory image cache.
  /// Synchronous — safe to call on the UI thread.
  static InMemoryCacheInfo getInMemoryInfo() {
    final cache = PaintingBinding.instance.imageCache;
    return InMemoryCacheInfo(
      sizeBytes: cache.currentSizeBytes,
      imageCount: cache.currentSize,
      maxSizeBytes: cache.maximumSizeBytes,
    );
  }

  /// Evicts all decoded images from Flutter's in-memory cache.
  /// Also clears live images (held by active Image widgets) so they will
  /// be re-fetched when their widgets next rebuild.
  static void clearInMemoryCache() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  }

  // ── App temporary directory ───────────────────────────────────────────────

  /// Returns the total size in bytes of all files in the app's temp directory.
  /// This includes any platform-level HTTP cache entries, thumbnail caches,
  /// and download-stage files the OS placed there on behalf of the app.
  static Future<int> getTempDirSize() async {
    final dir = await getTemporaryDirectory();
    var total = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length().catchError((_) => 0);
        }
      }
    } catch (_) {
      // Ignore permission errors or race conditions mid-enumeration.
    }
    return total;
  }

  /// Deletes all files and subdirectories inside the app's temp directory.
  /// The temp directory itself is kept (the OS manages it).
  static Future<void> clearTempDir() async {
    final dir = await getTemporaryDirectory();
    try {
      await for (final entity in dir.list(followLinks: false)) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {
          // Entry may already be gone or locked; skip it.
        }
      }
    } catch (_) {
      // Ignore errors for entries that disappeared or are still in use.
    }
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  /// Human-readable byte string: "0 B", "14.3 KB", "24.1 MB", "1.04 GB".
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (bytes < kb) return '$bytes B';
    if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / gb).toStringAsFixed(2)} GB';
  }
}
