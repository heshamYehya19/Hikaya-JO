/// UI string tables for the two supported app languages. Keys are shared;
/// each locale has a matching entry. Add new keys to BOTH maps together —
/// AppLocale.t() falls back to English if a key is missing from Arabic,
/// but that should only ever happen mid-edit, not in a committed state.
class AppStrings {
  AppStrings._();

  static const Map<String, String> en = {
    // Bottom nav (main_shell.dart)
    'nav_home': 'Home',
    'nav_journey': 'Journey',
    'nav_hunt': 'Hunt',
    'nav_talk': 'Talk',
    'nav_profile': 'Profile',

    // Home screen
    'home_greeting': 'Good Morning',
    'home_headline': "Discover Jordan's Hidden Stories",
    'home_plan_journey': 'Plan a Journey',
    'home_hikaya_hunt': 'Hikaya Hunt',
    'home_hikaya_talk': 'Hikaya Talk',
    'home_continue_journey': 'Continue Your Journey',
    'home_continue_button': 'Continue',
    'home_popular_destinations': 'Popular Destinations',
    'home_view_all': 'View All',
    'home_no_destinations': 'No destinations yet — run /seed',
    'home_load_error': "Couldn't load destinations",
    'unit_stops': 'stops',
    'unit_hours': 'hours',

    // Profile screen
    'profile_title': 'Profile',
    'profile_not_logged_in': 'Not logged in',
    'profile_coins': 'Coins',
    'profile_badges': 'Badges',
    'profile_visited': 'Visited',
    'profile_view_all_badges': 'View All Badges',
    'profile_app_language': 'App Language',
    'profile_app_language_subtitle': "Changes the whole app's display language",
    'profile_talk_languages': 'Talk Languages',
    'profile_talk_languages_subtitle': 'Default for Hikaya Talk',
    'profile_i_speak': 'I Speak',
    'profile_they_speak': 'They Speak',
    'profile_your_journeys': 'Your Journeys',
    'profile_no_journeys': 'No journeys yet — plan your first one!',

    // Journey planner input screen
    'plan_title': 'Plan Your Journey',
    'plan_subtitle': 'Craft your perfect adventure',
    'plan_interests_heading': 'What are you interested in?',
    'interest_history': 'History',
    'interest_nature': 'Nature',
    'interest_adventure': 'Adventure',
    'interest_culture': 'Culture',
    'interest_food': 'Food',
    'interest_relaxation': 'Relaxation',
    'plan_budget_heading': 'Budget',
    'plan_transport_heading': 'Transport',
    'transport_car': 'Car',
    'transport_bus': 'Bus',
    'transport_walking': 'Walking',
    'plan_hours_heading': 'How many hours?',
    'plan_generate_button': 'Generate My Journey',
    'plan_pick_interest_error': 'Pick at least one interest',
    'plan_generate_error': 'Failed to generate journey',

    // Hikaya Talk screen
    'talk_title': 'Hikaya Talk',
    'talk_i_speak': 'I Speak',
    'talk_they_speak': 'They Speak',
    'talk_you_said': 'You said',
    'talk_translated': 'Translated',
    'talk_tap_to_speak_hint': 'Tap the mic and start speaking…',
    'talk_translating': 'Translating…',
    'talk_translation_placeholder': 'Translation will appear here',
    'talk_listening': 'Listening…',
    'talk_tap_to_speak': 'Tap to speak',
    'talk_service_busy': 'Translation service is busy — please try again in a moment',
  };

  static const Map<String, String> ar = {
    // Bottom nav
    'nav_home': 'الرئيسية',
    'nav_journey': 'الرحلة',
    'nav_hunt': 'المطاردة',
    'nav_talk': 'المحادثة',
    'nav_profile': 'الملف الشخصي',

    // Home screen
    'home_greeting': 'صباح الخير',
    'home_headline': 'اكتشف قصص الأردن الخفية',
    'home_plan_journey': 'خطط رحلة',
    'home_hikaya_hunt': 'مطاردة حكاية',
    'home_hikaya_talk': 'حكاية توك',
    'home_continue_journey': 'أكمل رحلتك',
    'home_continue_button': 'متابعة',
    'home_popular_destinations': 'وجهات شائعة',
    'home_view_all': 'عرض الكل',
    'home_no_destinations': 'لا توجد وجهات بعد — شغّل /seed',
    'home_load_error': 'تعذر تحميل الوجهات',
    'unit_stops': 'محطات',
    'unit_hours': 'ساعات',

    // Profile screen
    'profile_title': 'الملف الشخصي',
    'profile_not_logged_in': 'لم يتم تسجيل الدخول',
    'profile_coins': 'العملات',
    'profile_badges': 'الأوسمة',
    'profile_visited': 'تمت زيارتها',
    'profile_view_all_badges': 'عرض جميع الأوسمة',
    'profile_app_language': 'لغة التطبيق',
    'profile_app_language_subtitle': 'تغيّر لغة عرض التطبيق بالكامل',
    'profile_talk_languages': 'لغات المحادثة',
    'profile_talk_languages_subtitle': 'الافتراضي لحكاية توك',
    'profile_i_speak': 'أنا أتحدث',
    'profile_they_speak': 'هم يتحدثون',
    'profile_your_journeys': 'رحلاتك',
    'profile_no_journeys': 'لا توجد رحلات بعد — خطط لأولى رحلاتك!',

    // Journey planner input screen
    'plan_title': 'خطط رحلتك',
    'plan_subtitle': 'صمم مغامرتك المثالية',
    'plan_interests_heading': 'ما الذي يثير اهتمامك؟',
    'interest_history': 'التاريخ',
    'interest_nature': 'الطبيعة',
    'interest_adventure': 'المغامرة',
    'interest_culture': 'الثقافة',
    'interest_food': 'الطعام',
    'interest_relaxation': 'الاسترخاء',
    'plan_budget_heading': 'الميزانية',
    'plan_transport_heading': 'وسيلة التنقل',
    'transport_car': 'سيارة',
    'transport_bus': 'حافلة',
    'transport_walking': 'مشياً',
    'plan_hours_heading': 'كم عدد الساعات؟',
    'plan_generate_button': 'أنشئ رحلتي',
    'plan_pick_interest_error': 'اختر اهتماماً واحداً على الأقل',
    'plan_generate_error': 'فشل إنشاء الرحلة',

    // Hikaya Talk screen
    'talk_title': 'حكاية توك',
    'talk_i_speak': 'أنا أتحدث',
    'talk_they_speak': 'هم يتحدثون',
    'talk_you_said': 'قلتَ',
    'talk_translated': 'الترجمة',
    'talk_tap_to_speak_hint': 'اضغط على الميكروفون وابدأ التحدث…',
    'talk_translating': 'جارٍ الترجمة…',
    'talk_translation_placeholder': 'ستظهر الترجمة هنا',
    'talk_listening': 'يستمع…',
    'talk_tap_to_speak': 'اضغط للتحدث',
    'talk_service_busy': 'خدمة الترجمة مشغولة — يرجى المحاولة مرة أخرى بعد قليل',
  };
}