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
      appBar: AppBar(
        title: const Text('Active Delivery'),
        backgroundColor: AppColors.travelerMode,
        foregroundColor: Colors.white,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Status indicator ─────────────────────
                    _StatusHeader(status: order.status),
                    const SizedBox(height: 24),

                    // ─── Pickup Info ──────────────────────────
                    _InfoSection(
                      icon: Icons.storefront_rounded,
                      iconColor: AppColors.accent,
                      title: 'Pickup from Store',
                      subtitle: order.store?.name ?? 'Store #${order.storeId}',
                      detail: order.store?.address,
                    ),
                    const SizedBox(height: 16),

                    // ─── Delivery Info ────────────────────────
                    _InfoSection(
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.primary,
                      title: 'Deliver to Requester',
                      subtitle: order.requester?.fullName ?? 'Requester',
                      detail:
                          '${order.requesterLat.toStringAsFixed(4)}, ${order.requesterLng.toStringAsFixed(4)}',
                    ),
                    const SizedBox(height: 16),

                    // ─── Items ────────────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Items to Pick Up',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                            const SizedBox(height: 8),
                            Text(order.itemsDescription),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Estimated Cost'),
                                Text(
                                    '₹${order.itemsEstimatedCost.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Your Bounty',
                                    style: TextStyle(
                                        color: AppColors.success)),
                                Text(
                                    '₹${order.bounty.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                      fontSize: 18,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Action Button ────────────────────────
                    if (order.status == OrderStatus.accepted)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await ref
                                .read(orderActionsProvider.notifier)
                                .markPickedUp(orderId);
                          },
                          icon: const Icon(Icons.shopping_bag_rounded),
                          label: const Text('Mark as Picked Up'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                    if (order.status == OrderStatus.pickedUp)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.pushNamed('deliveryComplete',
                                pathParameters: {
                                  'orderId': orderId.toString()
                                });
                          },
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('Complete Delivery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.travelerMode.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.travelerMode.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            status == OrderStatus.accepted
                ? Icons.directions_walk_rounded
                : Icons.delivery_dining_rounded,
            color: AppColors.travelerMode,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status == OrderStatus.accepted
                    ? 'Head to the store'
                    : 'Delivering to customer',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Text(
                status == OrderStatus.accepted
                    ? 'Pick up the items from the store'
                    : 'Ask for the 4-digit delivery code',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondaryLight),
              ),
            ],
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
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            if (detail != null)
              Text(detail!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }
}
