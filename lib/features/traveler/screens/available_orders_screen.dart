import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/order.dart';
import '../../../providers/orders_provider.dart';

/// Available orders screen for Travelers.
/// Shows orders that are waiting for a Traveler to accept.
class AvailableOrdersScreen extends ConsumerWidget {
  final bool embedded;

  const AvailableOrdersScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(availableOrdersProvider);

    final body = ordersAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Failed to load orders\n$e', textAlign: TextAlign.center),
          ],
        ),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_car_rounded,
                    size: 80,
                    color: AppColors.textSecondaryLight.withOpacity(0.3)),
                const SizedBox(height: 24),
                const Text('No delivery requests right now',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight)),
                const SizedBox(height: 8),
                const Text('Orders from nearby Buyers\nwill appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondaryLight, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _OrderRequestCard(
              order: order,
              onAccept: () async {
                final success = await ref
                    .read(orderActionsProvider.notifier)
                    .acceptOrder(order.id);
                if (success && context.mounted) {
                  context.pushNamed('activeDelivery',
                      pathParameters: {'orderId': order.id.toString()});
                }
              },
            );
          },
        );
      },
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Available Deliveries'),
        backgroundColor: AppColors.backgroundLight,
      ),
      body: body,
    );
  }
}

class _OrderRequestCard extends StatelessWidget {
  final Order order;
  final VoidCallback onAccept;

  const _OrderRequestCard({required this.order, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: bounty + delivery mode ──────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${order.bounty.toStringAsFixed(0)} Bounty',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (order.deliveryMode == DeliveryMode.express)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('EXPRESS',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                '${DateTime.now().difference(order.createdAt).inMinutes}m ago',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── Items ───────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.textSecondaryLight, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order.itemsDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryLight,
                      height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── Estimated cost ──────────────────────────────
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  color: AppColors.textSecondaryLight, size: 20),
              const SizedBox(width: 12),
              Text(
                'Estimated Cost: ₹${order.itemsEstimatedCost.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Accept button ───────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Accept Delivery',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
