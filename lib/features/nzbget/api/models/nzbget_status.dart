class NzbgetStatus {
  final bool paused;
  final int speed;
  final int remainingHigh;
  final int remainingLow;
  final int speedLimit;

  const NzbgetStatus({
    required this.paused,
    required this.speed,
    required this.remainingHigh,
    required this.remainingLow,
    required this.speedLimit,
  });

  factory NzbgetStatus.fromJson(Map<String, dynamic> json) {
    return NzbgetStatus(
      paused: json['DownloadPaused'] ?? true,
      speed: json['DownloadRate'] ?? 0,
      remainingHigh: json['RemainingSizeHi'] ?? 0,
      remainingLow: json['RemainingSizeLo'] ?? 0,
      speedLimit: json['DownloadLimit'] ?? 0,
    );
  }

  int get remainingSize => (remainingHigh << 32) + remainingLow;
}
