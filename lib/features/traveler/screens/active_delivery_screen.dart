import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/order.dart';
import '../../../providers/orders_provider.dart';
import '../widgets/sos_button.dart';

/// Active delivery screen for the Traveler.
/// Shows order pickup/delivery info and action buttons.
class ActiveDeliveryScreen extends ConsumerWidget {
  final int orderId;

  const ActiveDeliveryScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Active Delivery'),
        backgroundColor:
            AppColors.travelerMode, // Traveler primary color (#436850)
        foregroundColor: Colors.white,
      ),
      body: orderAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.travelerMode)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Status indicator ─────────────────────
                    _StatusHeader(status: order.status),
                    const SizedBox(height: 32),

                    // ─── Pickup Info ──────────────────────────
                    _InfoSection(
                      icon: Icons.storefront_rounded,
                      iconColor: AppColors.primary,
                      title: 'Pickup from Store',
                      subtitle: order.store?.name ?? 'Store #${order.storeId}',
                      detail: order.store?.address,
                    ),
                    const SizedBox(height: 16),

                    // ─── Delivery Info ────────────────────────
                    _InfoSection(
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.travelerMode,
                      title: 'Deliver to Buyer',
                      subtitle: order.requester?.fullName ?? 'Buyer',
                      detail:
                          '${order.requesterLat.toStringAsFixed(4)}, ${order.requesterLng.toStringAsFixed(4)}',
                    ),
                    const SizedBox(height: 24),

                    // ─── Items ────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shopping_bag_rounded,
                                  color: AppColors.travelerMode, size: 20),
                              SizedBox(width: 8),
                              Text('Items to Pick Up',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: AppColors.textPrimaryLight)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(order.itemsDescription,
                              style:
                                  const TextStyle(fontSize: 15, height: 1.4)),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimated Cost',
                                  style: TextStyle(
                                      color: AppColors.textSecondaryLight)),
                              Text(
                                  '₹${order.itemsEstimatedCost.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Your Bounty',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                                Text('₹${order.bounty.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      fontSize: 20,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ─── Action Button ────────────────────────
                    if (order.status == OrderStatus.accepted)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            await ref
                                .read(orderActionsProvider.notifier)
                                .markPickedUp(orderId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_rounded,
                                  color: Colors.white),
                              SizedBox(width: 8),
                              Text('Mark as Picked Up',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                    if (order.status == OrderStatus.pickedUp)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            context.pushNamed('deliveryComplete',
                                pathParameters: {
                                  'orderId': orderId.toString()
                                });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white),
                              SizedBox(width: 8),
                              Text('Complete Delivery',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 80), // Space for SOS button
                  ],
                ),
              ),

              // ─── SOS FAB ───────────────────────────────────
              const Positioned(
                bottom: 24,
                right: 24,
                child: SosButton(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final OrderStatus status;
  const _StatusHeader({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.travelerMode.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.travelerMode.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.travelerMode.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: Icon(
              status == OrderStatus.accepted
                  ? Icons.storefront_rounded
                  : Icons.delivery_dining_rounded,
              color: AppColors.travelerMode,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status == OrderStatus.accepted
                      ? 'Head to the store'
                      : 'Delivering to buyer',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.textPrimaryLight),
                ),
                const SizedBox(height: 4),
                Text(
                  status == OrderStatus.accepted
                      ? 'Pick up the items from the store'
                      : 'Ask for the 4-digit delivery code',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? detail;

  const _InfoSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimaryLight)),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondaryLight)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
