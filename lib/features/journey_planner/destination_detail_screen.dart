import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/services/story_guide_service.dart';
import '../../models/destination.dart';
import '../../providers/story_guide_provider.dart';
import '../business_directory/business_list_widget.dart';

class DestinationDetailScreen extends ConsumerStatefulWidget {
  final String destinationId;
  const DestinationDetailScreen({super.key, required this.destinationId});

  @override
  ConsumerState<DestinationDetailScreen> createState() => _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends ConsumerState<DestinationDetailScreen> {
  Destination? _destination;
  String? _story;
  bool _isLoadingDestination = true;
  bool _isLoadingStory = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoadingDestination = true;
      _error = null;
    });
    try {
      final service = ref.read(storyGuideServiceProvider);
      final destination = await service.fetchDestination(widget.destinationId);
      if (destination == null) {
        setState(() {
          _error = 'Destination not found';
          _isLoadingDestination = false;
        });
        return;
      }
      setState(() {
        _destination = destination;
        _isLoadingDestination = false;
      });
      _loadStory(service, destination);
    } catch (e) {
      setState(() {
        _error = 'Failed to load: $e';
        _isLoadingDestination = false;
      });
    }
  }

  Future<void> _loadStory(StoryGuideService service, Destination destination) async {
    setState(() => _isLoadingStory = true);
    try {
      final story = await service.getStory(destination);
      if (mounted) setState(() {
        _story = story;
        _isLoadingStory = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingStory = false);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'historical':
        return Icons.account_balance_outlined;
      case 'natural':
        return Icons.terrain_outlined;
      case 'cultural':
        return Icons.mosque_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_destination?.name ?? 'Destination')),
      body: SafeArea(
        child: _isLoadingDestination
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.deepTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_iconForType(_destination!.type), size: 56, color: AppColors.deepTeal),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _destination!.name,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.deepTeal),
                    ),
                  ),
                  if (_destination!.isLesserKnown)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.duneGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Hidden Gem',
                          style: TextStyle(fontSize: 12, color: AppColors.duneGold, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(_destination!.type, style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('~${_destination!.avgVisitMinutes} min', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 20),
              Text(_destination!.description, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 28),
              Row(
                children: [
                  Icon(Icons.auto_stories_outlined, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Text('Hikaya Story Guide',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.teal.withOpacity(0.2)),
                ),
                child: _isLoadingStory
                    ? Row(
                  children: [
                    const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text('Writing your story…', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                )
                    : Text(
                  _story ?? 'Story unavailable right now.',
                  style: const TextStyle(fontSize: 15, height: 1.6, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 28),
              BusinessListWidget(destinationId: widget.destinationId),
            ],
          ),
        ),
      ),
    );
  }
}