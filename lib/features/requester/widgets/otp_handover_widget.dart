import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// OTP Handover Widget — secure delivery confirmation.
///
/// For Requester: displays the 4-digit OTP prominently.
/// For Traveler: displays an input field to enter the OTP from the Requester.
///
/// Per PRD: OTP is ONLY visible to the Requester.
/// The Traveler must ask the Requester verbally for the code.
class OtpHandoverWidget extends StatelessWidget {
  final String otpCode;
  final bool isRequester;

  const OtpHandoverWidget({
    super.key,
    required this.otpCode,
    required this.isRequester,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRequester
              ? [AppColors.primary, AppColors.primaryDark]
              : [AppColors.accent, AppColors.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isRequester ? AppColors.primary : AppColors.accent)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                isRequester ? 'Your Delivery Code' : 'Enter Delivery Code',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isRequester) ...[
            // Requester sees the OTP
            Text(
              otpCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w800,
                letterSpacing: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this code with your Traveler\nat the time of delivery',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ] else ...[
            // Traveler sees a prompt
            const Text(
              'Ask the Requester for the\n4-digit delivery code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
