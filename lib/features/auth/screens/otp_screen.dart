import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';

/// OTP verification screen.
/// Shows a pin-code entry field for the 6-digit SMS OTP.
class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 6) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthService.verifyOtp(phone: widget.phone, token: otp);
      if (mounted) {
        context.goNamed('home');
      }
    } catch (e) {
      setState(() => _error = 'Invalid OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await AuthService.sendOtp(widget.phone);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend OTP')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mask phone for display: +91 98••••3210
    final maskedPhone = widget.phone.length >= 10
        ? '${widget.phone.substring(0, 6)}••••${widget.phone.substring(widget.phone.length - 4)}'
        : widget.phone;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Text(
                'Enter OTP',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to $maskedPhone',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: 40),

              // ─── PIN Input ────────────────────────────────────
              PinCodeTextField(
                appContext: context,
                controller: _otpController,
                length: 6,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: AppColors.surfaceLight,
                  inactiveFillColor: AppColors.surfaceLight,
                  selectedFillColor: AppColors.primary.withOpacity(0.05),
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.borderLight,
                  selectedColor: AppColors.primary,
                ),
                enableActiveFill: true,
                onCompleted: _verifyOtp,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.error, fontSize: 14),
                ),
              ],

              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Center(
                  child: TextButton(
                    onPressed: _resendOtp,
                    child: const Text('Resend OTP'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
