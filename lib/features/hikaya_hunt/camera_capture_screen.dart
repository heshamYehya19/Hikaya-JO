import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/colors.dart';
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
    // Recognizes the actual landmark and cross-checks its real coordinates
    // against this challenge's target location.
    final landmarkResult = await _landmarkService.detectLandmark(
      photo: _photo!,
      targetLat: widget.challenge.latitude,
      targetLng: widget.challenge.longitude,
    );

    late PhotoVerificationResult verification;

    if (landmarkResult.matched) {
      // Confidently recognized the right place — no need for the softer
      // AI check at all.
      verification = PhotoVerificationResult(plausible: true, reason: '');
    } else if (landmarkResult.landmarkName != null) {
      // Vision recognized *a* landmark, but it's not this one.
      verification = PhotoVerificationResult(
        plausible: false,
        reason: 'This looks like ${landmarkResult.landmarkName}, not ${widget.challenge.destinationName}.',
      );
    } else {
      // Tier 2: Vision found nothing recognizable — expected for
      // lesser-known destinations not in Google's landmark database.
      // Fall back to the loose Gemini plausibility check.
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
          title: const Text('Take another look?'),
          content: Text(
            verification.reason.isNotEmpty
                ? verification.reason
                : "This photo doesn't look like it matches ${widget.challenge.destinationName}.",
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
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.deepTeal, // gold
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.celebration_outlined, size: 48, color: AppColors.background),
                  ),
                  const SizedBox(height: 20),
                  Text('Challenge Complete!',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  if (_error == null)
                    Text('+${widget.challenge.rewardCoins} coins · "${widget.challenge.badgeName}" badge earned',
                        style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center)
                  else
                    Text(_error!, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst == false && route.settings.name != '/camera'),
                    child: const Text('Back to Hunt'),
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
      appBar: AppBar(title: const Text('Capture the Moment')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: _photo == null
                    ? Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.duneLight),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 56, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text('No photo yet', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_photo!, fit: BoxFit.cover, width: double.infinity),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) Text(_error!, style: TextStyle(color: AppColors.error)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(_photo == null ? 'Open Camera' : 'Retake Photo'),
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