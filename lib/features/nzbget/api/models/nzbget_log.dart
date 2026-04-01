class NzbgetLogItem {
  final int id;
  final String kind;
  final int time;
  final String text;

  const NzbgetLogItem({
    required this.id,
    required this.kind,
    required this.time,
    required this.text,
  });

  factory NzbgetLogItem.fromJson(Map<String, dynamic> json) {
    return NzbgetLogItem(
      id: json['ID'] ?? -1,
      kind: json['Kind'] ?? 'INFO',
      time: json['Time'] ?? 0,
      text: json['Text'] ?? '',
    );
  }

  DateTime? get timestamp => time > 0
      ? DateTime.fromMillisecondsSinceEpoch(time * 1000)
      : null;
}

class NzbgetLogs {
  final List<NzbgetLogItem> items;

  const NzbgetLogs({required this.items});

  factory NzbgetLogs.fromJson(List<dynamic> json) {
    return NzbgetLogs(
      items: json
          .map((item) => NzbgetLogItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
