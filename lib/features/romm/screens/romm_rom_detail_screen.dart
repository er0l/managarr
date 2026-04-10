import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/romm_rom.dart';
import '../api/romm_api.dart';
import '../providers/romm_providers.dart';

class RommRomDetailScreen extends ConsumerWidget {
  const RommRomDetailScreen({
    super.key,
    required this.instance,
    required this.romId,
    required this.romName,
  });

  final Instance instance;
  final int romId;
  final String romName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync =
        ref.watch(rommRomDetailProvider((instance: instance, romId: romId)));
    final api = ref.watch(rommApiProvider(instance));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Text(romName,
            style: const TextStyle(color: AppColors.textOnPrimary)),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.statusOffline),
              const SizedBox(height: 12),
              Text('$e'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(
                    rommRomDetailProvider((instance: instance, romId: romId))),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (rom) => _RomDetailBody(rom: rom, api: api),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail body
// ---------------------------------------------------------------------------

class _RomDetailBody extends StatefulWidget {
  const _RomDetailBody({required this.rom, required this.api});

  final RommRom rom;
  final RommApi api;

  @override
  State<_RomDetailBody> createState() => _RomDetailBodyState();
}

class _RomDetailBodyState extends State<_RomDetailBody> {
  bool _downloading = false;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    final rom = widget.rom;
    final api = widget.api;
    final coverUrl = api.coverUrl(rom);
    final isExternal = rom.urlCover != null && rom.urlCover!.isNotEmpty;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          if (coverUrl != null)
            SizedBox(
              width: double.infinity,
              height: 220,
              child: Image.network(
                coverUrl,
                fit: BoxFit.contain,
                headers:
                    isExternal ? null : {'Authorization': api.authHeader},
                errorBuilder: (_, _, _) => Container(
                  height: 220,
                  color: AppColors.tealPrimary.withAlpha(20),
                  child: const Icon(Icons.videogame_asset_outlined,
                      size: 64, color: AppColors.tealPrimary),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 160,
              color: AppColors.tealPrimary.withAlpha(20),
              child: const Icon(Icons.videogame_asset_outlined,
                  size: 64, color: AppColors.tealPrimary),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  rom.name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),

                // Platform + year + rating chips
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (rom.platformDisplayName.isNotEmpty)
                      _Chip(rom.platformDisplayName,
                          icon: Icons.videogame_asset_outlined),
                    if (rom.releaseYear != null)
                      _Chip(rom.releaseYear.toString(),
                          icon: Icons.calendar_today_outlined),
                    if (rom.averageRating != null &&
                        rom.averageRating! > 0)
                      _Chip(
                          '★ ${rom.averageRating!.toStringAsFixed(1)}',
                          color: Colors.amber),
                    if (rom.playerCount != null && rom.playerCount! > 0)
                      _Chip(
                          '${rom.playerCount} ${rom.playerCount == 1 ? 'player' : 'players'}',
                          icon: Icons.people_outline),
                  ],
                ),
                const SizedBox(height: 12),

                // Summary
                if (rom.summary != null && rom.summary!.isNotEmpty) ...[
                  _SectionLabel('Summary'),
                  const SizedBox(height: 4),
                  Text(rom.summary!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                ],

                // YouTube video
                if (rom.youtubeVideoId != null &&
                    rom.youtubeVideoId!.isNotEmpty)
                  _YouTubeCard(videoId: rom.youtubeVideoId!),

                // Genres
                if (rom.genres.isNotEmpty)
                  _ChipSection('Genres', rom.genres),

                // Game modes
                if (rom.gameModes.isNotEmpty)
                  _ChipSection('Game Modes', rom.gameModes),

                // Franchises
                if (rom.franchises.isNotEmpty)
                  _ChipSection('Franchises', rom.franchises),

                // Collections
                if (rom.collections.isNotEmpty)
                  _ChipSection('Collections', rom.collections),

                // Companies
                if (rom.companies.isNotEmpty)
                  _ChipSection('Companies', rom.companies),

                // Age ratings
                if (rom.ageRatings.isNotEmpty)
                  _ChipSection('Age Ratings', rom.ageRatings),

                // Regions
                if (rom.regions.isNotEmpty)
                  _ChipSection('Regions', rom.regions),

                // Languages
                if (rom.languages.isNotEmpty)
                  _ChipSection('Languages', rom.languages),

                // File info
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rom.fsName,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ),
                    if (rom.formattedSize.isNotEmpty)
                      Text(
                        rom.formattedSize,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Download button
                SizedBox(
                  width: double.infinity,
                  child: _downloading
                      ? Column(
                          children: [
                            LinearProgressIndicator(
                              value: _progress > 0 ? _progress : null,
                              color: AppColors.tealPrimary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _progress > 0
                                  ? '${(_progress * 100).toStringAsFixed(0)}%'
                                  : 'Downloading…',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        )
                      : FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.tealPrimary,
                          ),
                          onPressed: () => _download(api, rom),
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Download'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _download(RommApi api, RommRom rom) async {
    setState(() {
      _downloading = true;
      _progress = 0;
    });

    File? tempFile;
    try {
      // Download to temp directory first
      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/${rom.fsName}');

      final url = api.downloadUrl(rom.id, rom.fsName);
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 30),
        headers: {'Authorization': api.authHeader},
      ));

      await dio.download(
        url,
        tempFile.path,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (!mounted) return;

      // Read bytes from temp file and offer save dialog
      setState(() => _progress = 0); // reset while reading
      final Uint8List bytes = await tempFile.readAsBytes();

      if (!mounted) return;

      final result = await FilePicker.platform.saveFile(
        fileName: rom.fsName,
        bytes: bytes,
      );

      if (!mounted) return;

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Saved: ${rom.fsName}'),
          backgroundColor: AppColors.statusOnline,
          duration: const Duration(seconds: 4),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Save cancelled'),
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: AppColors.statusOffline,
        ));
      }
    } finally {
      // Clean up temp file
      try {
        await tempFile?.delete();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _downloading = false;
          _progress = 0;
        });
      }
    }
  }
}

// ---------------------------------------------------------------------------
// YouTube card
// ---------------------------------------------------------------------------

class _YouTubeCard extends StatelessWidget {
  const _YouTubeCard({required this.videoId});

  final String videoId;

  static Future<void> _openYouTube(BuildContext context, String videoId) async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      // Try YouTube app first; fall back to browser if not installed.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        messenger?.showSnackBar(SnackBar(
          content: Text('Could not open YouTube: $e'),
          backgroundColor: AppColors.statusOffline,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl =
        'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Trailer'),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  thumbnailUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: double.infinity,
                    height: 180,
                    color: Colors.black87,
                    child: const Icon(Icons.play_circle_outline,
                        size: 64, color: Colors.white54),
                  ),
                ),
                // Play button overlay
                GestureDetector(
                  onTap: () => _openYouTube(context, videoId),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 36),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => _openYouTube(context, videoId),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Watch on YouTube'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.tealPrimary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section helpers
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection(this.title, this.items);

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(title),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items.map((s) => _Chip(s)).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small chip widget
// ---------------------------------------------------------------------------

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? AppColors.tealPrimary).withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color ?? AppColors.tealPrimary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppColors.tealPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
