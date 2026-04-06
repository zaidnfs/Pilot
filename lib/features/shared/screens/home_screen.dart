import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/mode_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../features/requester/screens/store_list_screen.dart';
import '../../../features/traveler/screens/available_orders_screen.dart';
import '../widgets/mode_toggle.dart';

/// Home screen with the Dual-Mode toggle (Buyer ↔ Traveler).
/// Shows different content based on the selected mode.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    final profile = ref.watch(profileNotifierProvider);
    final isBuyer = mode == AppMode.requester;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Dashauli Connect',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              isBuyer ? 'Buyer Dashboard' : 'Traveler Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
                fontSize: 12,
              ),
            )
          ],
        ),
        backgroundColor: AppColors.backgroundLight,
        centerTitle: true,
        actions: [
          // KYC badge
          profile.whenOrNull(
                data: (p) => p != null && !p.aadhaarVerified
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: Badge(
                            smallSize: 10,
                            backgroundColor: AppColors.error,
                            child: const Icon(Icons.verified_user_outlined,
                                color: AppColors.primary),
                          ),
                          onPressed: () => context.pushNamed('kyc'),
                          tooltip: 'Complete KYC',
                        ),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),

          // Profile
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accentLight,
              child: IconButton(
                icon: const Icon(Icons.person_rounded,
                    size: 20, color: AppColors.primary),
                padding: EdgeInsets.zero,
                onPressed: () => context.pushNamed('profile'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Mode Toggle ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: ModeToggle(
              currentMode: mode,
              onToggle: () => ref.read(modeProvider.notifier).toggleMode(),
            ),
          ),

          // ─── Mode-specific content ────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: mode == AppMode.requester
                  ? const _RequesterView(key: ValueKey('requester'))
                  : const _TravelerView(key: ValueKey('traveler')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Requester mode: shows nearby stores and active orders.
class _RequesterView extends StatelessWidget {
  const _RequesterView({super.key});

  @override
  Widget build(BuildContext context) {
    return const StoreListScreen(embedded: true);
  }
}

/// Traveler mode: shows available orders along the route.
class _TravelerView extends StatelessWidget {
  const _TravelerView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AvailableOrdersScreen(embedded: true);
  }
}
