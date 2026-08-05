/// Shared interest→destination-type mapping, used by Home to personalize
/// both the "Popular Destinations" ordering and the hero header photo.
/// Photography has no strong match to historical/natural/cultural, so
/// it's intentionally left out rather than forced onto one.
const interestToDestinationTypes = {
  'History': ['historical'],
  'Culture': ['cultural'],
  'Food': ['cultural'],
  'Nature': ['natural'],
  'Adventure': ['natural'],
};

Set<String> matchedDestinationTypes(List<String> interests) {
  return interests.expand((i) => interestToDestinationTypes[i] ?? const <String>[]).toSet();
}