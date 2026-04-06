import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// SOS Emergency Button — always visible on active delivery screens.
///
/// Per PRD §4.2: Max 2 taps to reach emergency services.
/// Tap 1: Button press → Confirmation dialog
/// Tap 2: Confirm → Dials 112 (India emergency number)
class SosButton extends StatelessWidget {
  const SosButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: FloatingActionButton(
        heroTag: 'sos_button',
        backgroundColor: AppColors.error,
        onPressed: () => _showSosDialog(context),
        elevation: 6,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sos_rounded, color: Colors.white, size: 24),
            Text('SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                )),
          ],
        ),
      ),
    );
  }

  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 8),
            Text('Emergency SOS'),
          ],
        ),
        content: const Text(
          'This will call 112 (India Emergency Services).\n\n'
          'Only use in case of a genuine emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri(
                scheme: 'tel',
                path: AppConstants.emergencyNumber,
              );
              await launchUrl(uri);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Call 112'),
          ),
        ],
      ),
    );
  }
}
