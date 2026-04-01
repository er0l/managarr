import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../api/models/history_item.dart';
import '../api/models/queue_item.dart';
import '../api/sabnzbd_api.dart';

final sabnzbdApiProvider =
    Provider.family<SabnzbdApi, Instance>((ref, instance) {
  return SabnzbdApi.fromInstance(instance);
});

final sabnzbdQueueProvider =
    FutureProvider.autoDispose.family<SabnzbdQueue, Instance>(
        (ref, instance) async {
  return ref.read(sabnzbdApiProvider(instance)).getQueue();
});

final sabnzbdHistoryProvider =
    FutureProvider.autoDispose.family<List<SabnzbdHistoryItem>, Instance>(
        (ref, instance) async {
  return ref.read(sabnzbdApiProvider(instance)).getHistory();
});
