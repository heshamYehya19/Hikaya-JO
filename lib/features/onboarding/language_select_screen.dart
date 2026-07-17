import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/colors.dart';
import '../../core/services/app_prefs_service.dart';
import '../../models/talk_language.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  bool _isSaving = false;

  Future<void> _selectLanguage(TalkLanguage language) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    // "They speak" defaults to Arabic — this is a Jordan tourism app, so
    // that's the sensible default for everyone except Arabic speakers
    // themselves, who get English as the counterpart instead.
    final theirLanguage = language.translateCode == 'ar' ? kTalkLanguages[0] : kTalkLanguages[1];

    final prefs = AppPrefsService();
    await prefs.setLanguages(
      myLanguageCode: language.translateCode,
      theirLanguageCode: theirLanguage.translateCode,
    );

    // If a session already exists (e.g. reinstall on a device that was
    // never asked before, but Firebase Auth restored the login), sync
    // straight to Firestore too instead of waiting for the next signup.
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'myLanguage': language.translateCode,
          'theirLanguage': theirLanguage.translateCode,
        });
      } catch (_) {
        // Doc might not exist yet, or offline — signup/profile will set it later regardless.
      }
    }

    if (!mounted) return;

    if (userId != null) {
      context.goNamed('home');
    } else {
      context.goNamed('onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'What language do you speak?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                "We'll use this for Hikaya Talk and your default settings — you can change it anytime in Profile.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: kTalkLanguages.map((language) {
                    return GestureDetector(
                      onTap: () => _selectLanguage(language),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.duneLight),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(language.flag, style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(
                              language.name,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}