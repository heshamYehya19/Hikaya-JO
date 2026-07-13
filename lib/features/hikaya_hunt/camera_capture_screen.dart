import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/colors.dart';
import '../../core/services/hunt_service.dart';
import '../../models/challenge.dart';

class CameraCaptureScreen extends StatefulWidget {
  final Challenge challenge;
  const CameraCaptureScreen({super.key, required this.challenge});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  final _huntService = HuntService();
  File? _photo;
  bool _isSubmitting = false;
  bool _isDone = false;
  String? _error;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image != null) {
      setState(() => _photo = File(image.path));
    }
  }

  Future<void> _submit() async {
    if (_photo == null) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

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
        backgroundColor: AppColors.deepTeal,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.celebration_outlined, size: 72, color: Colors.white),
                  const SizedBox(height: 20),
                  Text('Challenge Complete!',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  if (_error == null)
                    Text('+${widget.challenge.rewardCoins} coins · "${widget.challenge.badgeName}" badge earned',
                        style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center)
                  else
                    Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_photo == null || _isSubmitting) ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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