import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/romm_rom.dart';
import '../api/romm_api.dart';
import '../screens/romm_rom_detail_screen.dart';

class RomGridCard extends StatelessWidget {
  const RomGridCard({
    super.key,
    required this.rom,
    required this.api,
    required this.instance,
  });

  final RommRom rom;
  final RommApi api;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final coverUrl = api.coverUrl(rom);
    final isExternal = rom.urlCover != null && rom.urlCover!.isNotEmpty;
    final authHeaders = isExternal ? null : {'Authorization': api.authHeader};

    Widget cover;
    if (coverUrl != null) {
      cover = Image.network(
        coverUrl,
        fit: BoxFit.cover,
        headers: authHeaders,
        errorBuilder: (e, st, tr) => _placeholder(),
      );
    } else {
      cover = _placeholder();
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RommRomDetailScreen(
            instance: instance,
            romId: rom.id,
            romName: rom.name,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(fit: StackFit.expand, children: [cover]),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rom.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          if (rom.releaseYear != null)
            Text(
              '${rom.releaseYear}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.tealPrimary.withAlpha(20),
      child: const Center(
        child: Icon(
          Icons.videogame_asset_outlined,
          color: AppColors.tealPrimary,
          size: 32,
        ),
      ),
    );
  }
}
