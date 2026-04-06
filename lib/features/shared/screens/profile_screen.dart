import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/auth_service.dart';

/// User profile screen showing KYC status, UPI ID, and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (p) {
          if (p == null) {
            return const Center(child: Text('Profile not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Avatar + Name ──────────────────────────────
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        p.fullName.isNotEmpty
                            ? p.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.fullName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      p.phone,
                      style: TextStyle(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── KYC Status ─────────────────────────────────
              _InfoTile(
                icon: p.aadhaarVerified
                    ? Icons.verified_user_rounded
                    : Icons.shield_outlined,
                iconColor:
                    p.aadhaarVerified ? AppColors.success : AppColors.warning,
                title: 'Aadhaar KYC',
                subtitle: p.aadhaarVerified
                    ? 'Verified as ${p.aadhaarMaskedName}'
                    : 'Not verified — tap to complete',
                onTap:
                    p.aadhaarVerified ? null : () => context.pushNamed('kyc'),
              ),
              const SizedBox(height: 12),

              // ─── UPI ID ─────────────────────────────────────
              _InfoTile(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.primary,
                title: 'UPI ID',
                subtitle:
                    p.upiId ?? 'Not set — required for receiving payments',
                onTap: () => _showUpiDialog(context, ref, p.upiId),
              ),
              const SizedBox(height: 12),

              // ─── My Store ───────────────────────────────────
              _InfoTile(
                icon: Icons.storefront_rounded,
                iconColor: AppColors.accent,
                title: 'My Store',
                subtitle: 'Register your shop on Dashauli Connect',
                onTap: () {
                  // TODO: Navigate to store registration
                },
              ),

              const SizedBox(height: 32),

              // ─── Sign Out ───────────────────────────────────
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.signOut();
                  if (context.mounted) context.goNamed('login');
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpiDialog(BuildContext context, WidgetRef ref, String? currentUpi) {
    final controller = TextEditingController(text: currentUpi);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set UPI ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'yourname@upi',
            labelText: 'UPI VPA',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final upiId = controller.text.trim();
              if (upiId.isNotEmpty) {
                await ref
                    .read(profileNotifierProvider.notifier)
                    .updateProfile({'upi_id': upiId});
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing:
            onTap != null ? const Icon(Icons.chevron_right_rounded) : null,
        onTap: onTap,
      ),
    );
  }
}
