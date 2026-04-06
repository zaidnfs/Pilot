import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';

/// Phone number login screen — first point of contact.
/// Mobile-first: large touch targets, single input, prominent CTA in thumb zone.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthService.sendOtp('+91$phone');
      if (mounted) {
        context.pushNamed('otp', extra: '+91$phone');
      }
    } catch (e) {
      setState(() => _error = 'Failed to send OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ─── Logo / Brand ─────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Dashauli Connect',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Community-powered delivery.\nZero commission.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
              ),

              const Spacer(flex: 2),

              // ─── Phone Input ──────────────────────────────────
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
                decoration: InputDecoration(
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🇮🇳 +91',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8),
                        SizedBox(
                          height: 24,
                          child: VerticalDivider(width: 1),
                        ),
                      ],
                    ),
                  ),
                  hintText: 'Phone number',
                  counterText: '',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 20),

              // ─── CTA Button (in thumb zone) ───────────────────
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue with OTP'),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'By continuing, you agree to our Terms of Service',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
