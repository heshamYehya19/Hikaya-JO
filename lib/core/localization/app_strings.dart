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
  };
}