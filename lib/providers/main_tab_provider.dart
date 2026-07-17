import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets a screen nested inside [MainShell] switch bottom-nav tabs
/// programmatically — e.g. Home's "Plan a Journey" quick-action button
/// jumping straight to the Journey tab, or "View All" jumping there too.
/// Index matches MainShell's tab order: 0 Home, 1 Journey, 2 Hunt, 3 Talk, 4 Profile.
final mainTabIndexProvider = StateProvider<int>((ref) => 0);
