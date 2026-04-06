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
      setState(() => _error = 'Wrong code. Ask the Requester again.');
      _otpController.clear();
    }

    setState(() => _isVerifying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Delivery'),
        backgroundColor: AppColors.success,
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
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.lock_open_rounded,
              size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 24),

        Text('Enter Delivery Code',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
          'Ask the Requester for their 4-digit code\nto confirm delivery',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 40),

        // ─── OTP Input ──────────────────────────────────────
        PinCodeTextField(
          appContext: context,
          controller: _otpController,
          length: 4,
          keyboardType: TextInputType.number,
          animationType: AnimationType.scale,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(14),
            fieldHeight: 64,
            fieldWidth: 56,
            activeFillColor: AppColors.surfaceLight,
            inactiveFillColor: AppColors.surfaceLight,
            selectedFillColor: AppColors.success.withOpacity(0.05),
            activeColor: AppColors.success,
            inactiveColor: AppColors.borderLight,
            selectedColor: AppColors.success,
          ),
          enableActiveFill: true,
          onCompleted: _verifyOtp,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: AppColors.error, fontSize: 14)),
        ],

        if (_isVerifying)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: CircularProgressIndicator(),
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
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              size: 64, color: AppColors.success),
        ),
        const SizedBox(height: 24),

        Text('Delivery Complete! 🎉',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
          'The order has been delivered successfully.\nPayment has been confirmed.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondaryLight),
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
            ),
            child: const Text('Back to Home'),
          ),
        ),
      ],
    );
  }
}
