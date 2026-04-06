import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// OTP Handover Widget — secure delivery confirmation.
///
/// For Requester: displays the 4-digit OTP prominently.
/// For Traveler: displays an input field to enter the OTP from the Requester.
///
/// Per design update: OTP must be large, high-contrast (#12372A on #FBFADA)
/// for outdoor visibility in Dashauli.
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight, // Cream background for high contrast
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primary, width: 2), // Prominent border
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                isRequester ? 'Secure Delivery Code' : 'Enter Delivery Code',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isRequester) ...[
            // Requester sees the OTP with massive, high-contrast text
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                otpCode,
                style: const TextStyle(
                  color: AppColors.primary, // #12372A dark text
                  fontSize: 52, // Huge size for outdoor visibility
                  fontWeight: FontWeight.w900,
                  letterSpacing: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share this code with your Traveler\nONLY when they arrive with your items.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            // Traveler sees a prompt
            const Text(
              'Ask the Requester for the\n4-digit delivery code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Input field would go here for traveler, handled in delivery_complete_screen
          ],
        ],
      ),
    );
  }
}
