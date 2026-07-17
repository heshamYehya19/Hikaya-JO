import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../providers/journey_provider.dart';
import '../../widgets/destination_card.dart';
import 'destination_detail_screen.dart';

/// Full destinations list — this is what Home's "View All" button opens.
/// Reuses the same allDestinationsProvider and DestinationCard as the
/// Home carousel, just laid out as a scrollable grid instead of a row.
class AllDestinationsScreen extends ConsumerWidget {
  const AllDestinationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationsAsync = ref.watch(allDestinationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('All Destinations')),
      body: SafeArea(
        child: destinationsAsync.when(
          data: (destinations) {
            if (destinations.isEmpty) {
              return Center(
                child: Text(
                  'No destinations yet — run /seed',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemCount: destinations.length,
              itemBuilder: (_, i) => DestinationCard(
                destination: destinations[i],
                width: double.infinity,
                height: double.infinity,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DestinationDetailScreen(destinationId: destinations[i].id),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(
              "Couldn't load destinations",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
