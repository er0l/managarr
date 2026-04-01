class TautulliGraphData {
  final List<String> categories;
  final List<TautulliGraphSeries> series;

  const TautulliGraphData({required this.categories, required this.series});

  factory TautulliGraphData.fromJson(Map<String, dynamic> json) {
    return TautulliGraphData(
      categories: (json['categories'] as List? ?? []).cast<String>(),
      series: (json['series'] as List? ?? [])
          .map((s) => TautulliGraphSeries.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isEmpty => categories.isEmpty || series.isEmpty;
}

class TautulliGraphSeries {
  final String name;
  final List<int> data;

  const TautulliGraphSeries({required this.name, required this.data});

  factory TautulliGraphSeries.fromJson(Map<String, dynamic> json) {
    return TautulliGraphSeries(
      name: json['name'] as String? ?? '',
      data: (json['data'] as List? ?? [])
          .map((e) => (e as num?)?.toInt() ?? 0)
          .toList(),
    );
  }

  int get total => data.fold(0, (a, b) => a + b);
}
