enum LidarrSortOption {
  alphabetical('Alphabetical'),
  dateAdded('Date Added'),
  tracks('Tracks'),
  size('Size'),
  qualityProfile('Quality Profile'),
  metadataProfile('Metadata Profile'),
  type('Type');

  const LidarrSortOption(this.label);
  final String label;
}

enum LidarrFilterOption {
  all('All'),
  monitored('Monitored'),
  unmonitored('Unmonitored'),
  missing('Missing');

  const LidarrFilterOption(this.label);
  final String label;
}
