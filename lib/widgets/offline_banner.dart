import 'package:flutter/material.dart';
import '../core/services/offline_service.dart';
import '../core/theme/colors.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: OfflineService().connectivityStream,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        if (isOnline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: AppColors.warning.withOpacity(0.15),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 14, color: AppColors.warning),
              const SizedBox(width: 6),
              Text('Offline — showing downloaded content', style: TextStyle(fontSize: 12, color: AppColors.warning)),
            ],
          ),
        );
      },
    );
  }
}