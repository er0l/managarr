enum RadarrSortOption {
  alphabetical('Alphabetical'),
  dateAdded('Date Added'),
  digitalRelease('Digital Release'),
  inCinemas('In Cinemas'),
  physicalRelease('Physical Release'),
  qualityProfile('Quality Profile'),
  runtime('Runtime'),
  size('Size'),
  studio('Studio'),
  year('Year');

  final String label;
  const RadarrSortOption(this.label);
}

enum RadarrFilterOption {
  all('All'),
  monitored('Monitored'),
  unmonitored('Unmonitored'),
  missing('Missing'),
  wanted('Wanted'),
  cutoffUnmet('Cutoff Unmet');

  final String label;
  const RadarrFilterOption(this.label);
}
