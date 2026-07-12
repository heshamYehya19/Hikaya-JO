import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/story_guide_service.dart';

final storyGuideServiceProvider = Provider<StoryGuideService>((ref) => StoryGuideService());