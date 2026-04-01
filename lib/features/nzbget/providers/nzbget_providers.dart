import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../api/models/nzbget_history.dart';
import '../api/models/nzbget_queue.dart';
import '../api/models/nzbget_status.dart';
import '../api/models/nzbget_log.dart';
import '../api/nzbget_api.dart';

final nzbgetApiProvider = Provider.family<NzbgetApi, Instance>((ref, instance) {
  return NzbgetApi.fromInstance(instance);
});

final nzbgetStatusProvider =
    FutureProvider.autoDispose.family<NzbgetStatus, Instance>(
        (ref, instance) async {
  return ref.watch(nzbgetApiProvider(instance)).getStatus();
});

final nzbgetQueueProvider =
    FutureProvider.autoDispose.family<NzbgetQueue, Instance>(
        (ref, instance) async {
  return ref.watch(nzbgetApiProvider(instance)).getQueue();
});

final nzbgetHistoryProvider =
    FutureProvider.autoDispose.family<NzbgetHistory, Instance>(
        (ref, instance) async {
  return ref.watch(nzbgetApiProvider(instance)).getHistory();
});

final nzbgetLogsProvider =
    FutureProvider.autoDispose.family<NzbgetLogs, Instance>(
        (ref, instance) async {
  return ref.watch(nzbgetApiProvider(instance)).getLogs();
});
