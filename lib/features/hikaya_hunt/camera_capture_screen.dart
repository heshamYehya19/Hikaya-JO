import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/services/hunt_service.dart';
import '../../core/services/photo_verification_service.dart';
import '../../core/services/landmark_verification_service.dart';
import '../../models/challenge.dart';

class CameraCaptureScreen extends StatefulWidget {
  final Challenge challenge;
  const CameraCaptureScreen({super.key, required this.challenge});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
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
        reason: 'This looks like ${landmarkResult.landmarkName}, not ${widget.challenge.destinationName}.',
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
          title: const Text('Take another look?', style: TextStyle(color: AppColors.textPrimary)),
          content: Text(
            verification.reason.isNotEmpty
                ? verification.reason
                : "This photo doesn't look like it matches ${widget.challenge.destinationName}.",
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retake Photo')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit Anyway')),
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
        if (!awarded) _error = 'Already completed — no duplicate reward given';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to submit: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('Congratulations!', style: AppTypography.headline1.copyWith(fontSize: 26), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  const Text(
                    "You unlocked a new story!",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (_error == null) ...[
                    Text(
                      '+${widget.challenge.rewardCoins} Coins Earned',
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
                          Text('"${widget.challenge.badgeName}" badge earned', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ] else
                    Text(_error!, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // Fixed: the old popUntil predicate checked route.settings.name,
                      // but none of these routes are named, so it silently popped
                      // all the way to the app's very first screen instead of just
                      // back to the challenge list. This pops exactly the 2 screens
                      // pushed to get here (camera + challenge detail).
                      onPressed: () => Navigator.of(context)
                        ..pop()
                        ..pop(),
                      child: const Text('Great!'),
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
              Text("You're in the right place!", style: AppTypography.headline2.copyWith(fontSize: 20)),
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 20),
                child: Text('Take a photo to unlock the story', style: AppTypography.bodySecondary),
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
                        const Text('No photo yet', style: TextStyle(color: AppColors.textSecondary)),
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
                  label: Text(_photo == null ? 'Take Photo & Unlock' : 'Retake Photo'),
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
                      : const Text('Complete Challenge'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}