enum SonarrSortOption {
  alphabetical('Alphabetical'),
  dateAdded('Date Added'),
  episodes('Episodes'),
  network('Network'),
  nextAiring('Next Airing'),
  previousAiring('Previous Airing'),
  qualityProfile('Quality Profile'),
  size('Size'),
  type('Type');

  final String label;
  const SonarrSortOption(this.label);
}

enum SonarrFilterOption {
  all('All'),
  monitored('Monitored'),
  unmonitored('Unmonitored'),
  continuing('Continuing'),
  ended('Ended'),
  missing('Missing');

  final String label;
  const SonarrFilterOption(this.label);
}
