import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/mode_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../features/requester/screens/store_list_screen.dart';
import '../../../features/traveler/screens/available_orders_screen.dart';
import '../widgets/mode_toggle.dart';

/// Home screen with the Dual-Mode toggle (Requester ↔ Traveler).
/// Shows different content based on the selected mode.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    final profile = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashauli Connect',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          // KYC badge
          profile.whenOrNull(
                data: (p) => p != null && !p.aadhaarVerified
                    ? IconButton(
                        icon: Badge(
                          smallSize: 8,
                          backgroundColor: AppColors.warning,
                          child: const Icon(Icons.shield_outlined),
                        ),
                        onPressed: () => context.pushNamed('kyc'),
                        tooltip: 'Complete KYC',
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),

          // Profile
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.pushNamed('profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Mode Toggle ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ModeToggle(
              currentMode: mode,
              onToggle: () => ref.read(modeProvider.notifier).toggleMode(),
            ),
          ),

          // ─── Mode-specific content ────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
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
