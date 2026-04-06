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
      loading: () => const Center(child: CircularProgressIndicator()),
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
                Icon(Icons.delivery_dining_rounded,
                    size: 64,
                    color: AppColors.textSecondaryLight.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No delivery requests right now',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text(
                    'Orders from nearby Requesters\nwill appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondaryLight)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      appBar: AppBar(title: const Text('Available Deliveries')),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: bounty + delivery mode ──────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${order.bounty.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (order.deliveryMode == DeliveryMode.express)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 14, color: AppColors.accent),
                        SizedBox(width: 2),
                        Text('EXPRESS',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent)),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(
                  '${DateTime.now().difference(order.createdAt).inMinutes}m ago',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── Items ───────────────────────────────────────
            Text(
              order.itemsDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 8),

            // ─── Estimated cost ──────────────────────────────
            Text(
              'Items ~₹${order.itemsEstimatedCost.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),

            // ─── Accept button ───────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Accept Delivery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
