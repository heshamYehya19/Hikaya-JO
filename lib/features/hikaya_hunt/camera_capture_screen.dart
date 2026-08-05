import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/localization/app_locale.dart';
import '../../core/services/hunt_service.dart';
import '../../core/services/photo_verification_service.dart';
import '../../core/services/landmark_verification_service.dart';
import '../../models/challenge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/notification_service.dart';
import '../../providers/journey_provider.dart';

class CameraCaptureScreen extends ConsumerStatefulWidget {
  final Challenge challenge;
  const CameraCaptureScreen({super.key, required this.challenge});

  @override
  ConsumerState<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen> {
  final _huntService = HuntService();
  final _landmarkService = LandmarkVerificationService();
  final _verificationService = PhotoVerificationService();
  File? _photo;
  bool _isSubmitting = false;
  bool _isVerifying = false;
  bool _isDone = false;
  String? _error;

  Future<void> _takePhoto({ImageSource source = ImageSource.camera}) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      setState(() => _photo = File(image.path));
    }
  }

  Future<void> _submit() async {
    if (_photo == null) return;
    final t = AppLocale.of(context).t;
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    // Tier 1: Cloud Vision landmark detection — precise and deterministic.
    final landmarkResult = await _landmarkService.detectLandmark(
      photo: _photo!,
      targetLat: widget.challenge.latitude,
      targetLng: widget.challenge.longitude,
    );

    late PhotoVerificationResult verification;

    if (landmarkResult.matched) {
      verification = PhotoVerificationResult(plausible: true, reason: '');
    } else if (landmarkResult.landmarkName != null) {
      verification = PhotoVerificationResult(
        plausible: false,
        reason: '${t('hunt_camera_wrong_landmark')} ${landmarkResult.landmarkName}, ${t('hunt_camera_wrong_landmark_not')} ${widget.challenge.destinationName}.',
      );
    } else {
      // Tier 2: fall back to the looser Gemini plausibility check.
      verification = await _verificationService.verifyPhoto(
        photo: _photo!,
        challengeTitle: widget.challenge.title,
        challengeDescription: widget.challenge.description,
        destinationName: widget.challenge.destinationName,
      );
    }

    setState(() => _isVerifying = false);

    if (!verification.plausible && mounted) {
      final proceedAnyway = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(t('hunt_camera_retake_dialog_title'), style: const TextStyle(color: AppColors.textPrimary)),
          content: Text(
            verification.reason.isNotEmpty
                ? verification.reason
                : "${t('hunt_camera_retake_dialog_default')} ${widget.challenge.destinationName}.",
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('hunt_camera_retake_photo_btn'))),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t('hunt_camera_submit_anyway'))),
          ],
        ),
      );
      if (proceedAnyway != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final ref = FirebaseStorage.instance.ref('challenge_photos/$userId/${widget.challenge.id}.jpg');
        await ref.putFile(_photo!);
      }

      final awarded = await _huntService.completeChallenge(widget.challenge);

      setState(() {
        _isDone = true;
        _isSubmitting = false;
        if (!awarded) _error = t('hunt_camera_already_completed');
      });

      // Same check as Story Mode: if this challenge's destination was the
      // last unvisited stop on the currently active journey, the "come
      // back and finish" reminder is now pointless — cancel it.
      final activeJourney = ref.read(currentJourneyProvider);
      if (activeJourney != null) {
        final stopIds = activeJourney.stops.map((s) => s.destinationId).toSet();
        if (stopIds.contains(widget.challenge.destinationId)) {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
            final visited = Set<String>.from(doc.data()?['visitedLocations'] ?? []);
            if (stopIds.every(visited.contains)) {
              await NotificationService.cancelJourneyReminder(activeJourney.id);
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _error = '${t('hunt_camera_submit_failed')} $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.of(context).t;

    if (_isDone) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.deepTeal, shape: BoxShape.circle),
                    child: const Icon(Icons.star_rounded, size: 52, color: AppColors.background),
                  ),
                  const SizedBox(height: 24),
                  Text(t('hunt_camera_congrats'), style: AppTypography.headline1.copyWith(fontSize: 26), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    t('hunt_camera_unlocked'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (_error == null) ...[
                    Text(
                      '+${widget.challenge.rewardCoins} ${t('hunt_camera_coins_earned')}',
                      style: const TextStyle(color: AppColors.duneGold, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.duneLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events, size: 16, color: AppColors.deepTeal),
                          const SizedBox(width: 8),
                          Text('"${widget.challenge.badgeName}" ${t('hunt_camera_badge_earned')}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ] else
                    Text(_error!, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context)
                        ..pop()
                        ..pop(),
                      child: Text(t('hunt_camera_great')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(t('hunt_camera_you_are_here'), style: AppTypography.headline2.copyWith(fontSize: 20)),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 20),
                child: Text(t('hunt_camera_subtitle'), style: AppTypography.bodySecondary),
              ),
              Expanded(
                child: _photo == null
                    ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.duneLight),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.surfaceElevated, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.duneGold),
                        ),
                        const SizedBox(height: 14),
                        Text(t('hunt_camera_no_photo'), style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(_photo!, fit: BoxFit.cover, width: double.infinity),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(_photo == null ? t('hunt_take_photo_unlock') : t('hunt_camera_retake')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.duneLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _takePhoto(source: ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('🧪 DEV: Choose from Gallery (testing only)'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_photo == null || _isSubmitting || _isVerifying) ? null : _submit,
                  child: (_isSubmitting || _isVerifying)
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                      : Text(t('hunt_camera_complete')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}