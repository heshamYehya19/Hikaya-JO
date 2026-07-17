import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../models/talk_language.dart';

/// Dropdown language picker used by both Hikaya Talk (per-session choice)
/// and Profile (saved default). Shared here so both stay visually and
/// behaviorally identical instead of drifting apart.
class LanguagePicker extends StatelessWidget {
  final String label;
  final TalkLanguage language;
  final ValueChanged<TalkLanguage> onChanged;

  const LanguagePicker({super.key, required this.label, required this.language, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.duneLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<TalkLanguage>(
              value: language,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              items: kTalkLanguages
                  .map((lang) => DropdownMenuItem(
                value: lang,
                child: Text('${lang.flag}  ${lang.name}'),
              ))
                  .toList(),
              onChanged: (lang) {
                if (lang != null) onChanged(lang);
              },
            ),
          ),
        ],
      ),
    );
  }
}