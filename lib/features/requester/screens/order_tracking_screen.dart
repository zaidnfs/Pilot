import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/order.dart';
import '../../../providers/orders_provider.dart';
import '../widgets/otp_handover_widget.dart';
import '../../traveler/widgets/sos_button.dart';

/// Order tracking screen for the Requester.
/// Shows order status, Traveler identity, and OTP handover widget.
class OrderTrackingScreen extends ConsumerWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Status')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Status Badge ────────────────────────────────
                Center(
                  child: _StatusBadge(status: order.status),
                ),
                const SizedBox(height: 24),

                // ─── Order Details ───────────────────────────────
                _DetailCard(
                  title: 'Order #${order.id}',
                  children: [
                    _DetailRow('Items', order.itemsDescription),
                    _DetailRow('Estimated Cost',
                        '₹${order.itemsEstimatedCost.toStringAsFixed(0)}'),
                    _DetailRow('Delivery Bounty',
                        '₹${order.bounty.toStringAsFixed(0)}'),
                    _DetailRow('Mode',
                        order.deliveryMode == DeliveryMode.express
                            ? '⚡ Express'
                            : '🕐 Standard'),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Traveler Info (if accepted) ─────────────────
                if (order.travelerId != null) ...[
                  _DetailCard(
                    title: 'Your Traveler',
                    children: [
                      // Per PRD: Traveler's Aadhaar photo + masked name
                      // must be displayed persistently during active trip
                      if (order.traveler?.aadhaarPhotoUrl != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundImage: NetworkImage(
                                  order.traveler!.aadhaarPhotoUrl!),
                            ),
                          ),
                        ),
                      _DetailRow('Name',
                          order.traveler?.aadhaarMaskedName ?? 'Verified Traveler'),
                      _DetailRow('Phone', order.traveler?.phone ?? ''),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── OTP Handover (shown when picked_up) ─────────
                if (order.status == OrderStatus.pickedUp &&
                    order.otpCode != null) ...[
                  OtpHandoverWidget(
                    otpCode: order.otpCode!,
                    isRequester: true,
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── Status Timeline ─────────────────────────────
                _StatusTimeline(order: order),

                // ─── SOS Button ──────────────────────────────────
                if (order.status.isActive) ...[
                  const SizedBox(height: 24),
                  const SosButton(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            _statusLabel(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.requested: return AppColors.statusRequested;
      case OrderStatus.accepted: return AppColors.statusAccepted;
      case OrderStatus.pickedUp: return AppColors.statusPickedUp;
      case OrderStatus.delivered: return AppColors.statusDelivered;
      case OrderStatus.cancelled: return AppColors.statusCancelled;
    }
  }

  IconData _statusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.requested: return Icons.access_time_rounded;
      case OrderStatus.accepted: return Icons.handshake_rounded;
      case OrderStatus.pickedUp: return Icons.delivery_dining_rounded;
      case OrderStatus.delivered: return Icons.check_circle_rounded;
      case OrderStatus.cancelled: return Icons.cancel_rounded;
    }
  }

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.requested: return 'Waiting for Traveler';
      case OrderStatus.accepted: return 'Traveler Assigned';
      case OrderStatus.pickedUp: return 'On the Way';
      case OrderStatus.delivered: return 'Delivered ✓';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _DetailCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final Order order;
  const _StatusTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Timeline',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            _TimelineItem('Order Placed', order.createdAt, true),
            if (order.status.index >= OrderStatus.accepted.index)
              _TimelineItem('Traveler Accepted', order.createdAt, true),
            if (order.pickupAt != null)
              _TimelineItem('Picked Up', order.pickupAt!, true),
            if (order.deliveredAt != null)
              _TimelineItem('Delivered', order.deliveredAt!, true),
            if (order.cancelledAt != null)
              _TimelineItem('Cancelled', order.cancelledAt!, true),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String label;
  final DateTime time;
  final bool completed;

  const _TimelineItem(this.label, this.time, this.completed);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: completed ? AppColors.success : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}
