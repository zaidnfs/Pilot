import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/orders_provider.dart';

/// Delivery completion screen — Traveler enters the OTP, then pays.
class DeliveryCompleteScreen extends ConsumerStatefulWidget {
  final int orderId;

  const DeliveryCompleteScreen({super.key, required this.orderId});

  @override
  ConsumerState<DeliveryCompleteScreen> createState() =>
      _DeliveryCompleteScreenState();
}

class _DeliveryCompleteScreenState
    extends ConsumerState<DeliveryCompleteScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isVerified = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 4) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final success = await ref
        .read(orderActionsProvider.notifier)
        .verifyDeliveryOtp(widget.orderId, otp);

    if (success) {
      setState(() => _isVerified = true);
    } else {
      setState(() => _error = 'Wrong code. Ask the Buyer again.');
      _otpController.clear();
    }

    setState(() => _isVerifying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Complete Delivery'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isVerified ? _buildSuccessView() : _buildOtpView(),
        ),
      ),
    );
  }

  Widget _buildOtpView() {
    return Column(
      children: [
        const Spacer(),
        // ─── Lock icon ──────────────────────────────────────
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ]),
            child: const Icon(Icons.security_rounded,
                size: 50, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 32),

        Center(
          child: Text('Enter Delivery Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight)),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Ask the Buyer for their 4-digit code\nto securely confirm this delivery.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondaryLight, fontSize: 15, height: 1.4),
          ),
        ),
        const SizedBox(height: 48),

        // ─── OTP Input ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PinCodeTextField(
            appContext: context,
            controller: _otpController,
            length: 4,
            keyboardType: TextInputType.number,
            animationType: AnimationType.scale,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(16),
              fieldHeight: 72,
              fieldWidth: 64,
              activeFillColor: AppColors.surfaceLight,
              inactiveFillColor: AppColors.surfaceLight,
              selectedFillColor: AppColors.primary.withOpacity(0.05),
              activeColor: AppColors.primary,
              inactiveColor: AppColors.borderLight,
              selectedColor: AppColors.primary,
              borderWidth: 2,
            ),
            textStyle: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primary),
            enableActiveFill: true,
            onCompleted: _verifyOtp,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Text(_error!,
                      style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],

        if (_isVerifying)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ),

        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const Spacer(),
        // ─── Success animation ──────────────────────────────
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 80, color: AppColors.success),
          ),
        ),
        const SizedBox(height: 32),

        Center(
          child: Text('Delivery Complete! 🎉',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.success)),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'The order has been delivered successfully.\nBounty payment has been credited.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondaryLight, fontSize: 15, height: 1.4),
          ),
        ),

        const Spacer(),

        // ─── Back to home ───────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.goNamed('home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Back to Home',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
