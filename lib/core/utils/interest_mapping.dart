/// Shared interest→destination-type mapping, used by Home to personalize
/// both the "Popular Destinations" ordering and the hero header photo, and
/// by the Journey Planner to pre-filter which destinations go into the AI
/// prompt. Photography has no strong match to historical/natural/cultural,
/// so it's intentionally left out rather than forced onto one — same for
/// "relaxation" from the Journey Planner's picker.
///
/// Callers pass interests from two different sources with different
/// casing — onboarding's InterestsSetupScreen saves display labels like
/// "History", while the Journey Planner's own picker uses lowercase keys
/// like "history" — so lookups here are case-insensitive rather than
/// requiring both call sites to agree on a casing convention.
const interestToDestinationTypes = {
  'history': ['historical'],
  'culture': ['cultural'],
  'food': ['cultural'],
  'nature': ['natural'],
  'adventure': ['natural'],
};

Set<String> matchedDestinationTypes(List<String> interests) {
  return interests
      .expand((i) => interestToDestinationTypes[i.toLowerCase()] ?? const <String>[])
      .toSet();
}