import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../api/models/romm_platform.dart';
import '../api/models/romm_rom.dart';
import '../api/romm_api.dart';

final rommApiProvider = Provider.family<RommApi, Instance>(
    (ref, instance) => RommApi.fromInstance(instance));

final rommPlatformsProvider =
    FutureProvider.autoDispose.family<List<RommPlatform>, Instance>(
        (ref, instance) =>
            ref.watch(rommApiProvider(instance)).getPlatforms());

typedef RommRomsKey = ({Instance instance, int platformId, String searchTerm});

final rommRomsProvider = FutureProvider.autoDispose
    .family<List<RommRom>, RommRomsKey>((ref, key) {
  final api = ref.watch(rommApiProvider(key.instance));
  return api.getRoms(
    key.platformId,
    searchTerm: key.searchTerm.isEmpty ? null : key.searchTerm,
  );
});

final rommRomDetailProvider = FutureProvider.autoDispose
    .family<RommRom, ({Instance instance, int romId})>(
        (ref, key) =>
            ref.watch(rommApiProvider(key.instance)).getRomDetail(key.romId));
