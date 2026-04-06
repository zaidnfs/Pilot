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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: AppColors.backgroundLight,
      ),
      body: orderAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Status Badge ────────────────────────────────
                Center(
                  child: _StatusBadge(status: order.status),
                ),
                const SizedBox(height: 32),

                // ─── Order Details ───────────────────────────────
                _DetailCard(
                  title: 'Order #${order.id}',
                  icon: Icons.receipt_long_rounded,
                  children: [
                    _DetailRow('Items', order.itemsDescription),
                    const Divider(height: 24),
                    _DetailRow('Estimated Cost',
                        '₹${order.itemsEstimatedCost.toStringAsFixed(0)}'),
                    _DetailRow('Delivery Bounty',
                        '₹${order.bounty.toStringAsFixed(0)}'),
                    const Divider(height: 24),
                    _DetailRow(
                        'Mode',
                        order.deliveryMode == DeliveryMode.express
                            ? '⚡ Express'
                            : '🕐 Standard'),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Traveler Info (if accepted) ─────────────────
                if (order.travelerId != null) ...[
                  _DetailCard(
                    title: 'Your Traveler',
                    icon: Icons.person_pin_circle_rounded,
                    children: [
                      // Per PRD: Traveler's Aadhaar photo + masked name
                      // must be displayed persistently during active trip
                      if (order.traveler?.aadhaarPhotoUrl != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(
                                    order.traveler!.aadhaarPhotoUrl!),
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary, width: 2),
                              ),
                              child: const CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.surfaceLight,
                                child: Icon(Icons.person,
                                    size: 40, color: AppColors.primaryLight),
                              ),
                            ),
                          ),
                        ),
                      _DetailRow(
                          'Name',
                          order.traveler?.aadhaarMaskedName ??
                              'Verified Traveler',
                          isBold: true),
                      _DetailRow('Phone', order.traveler?.phone ?? ''),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // ─── OTP Handover (shown when picked_up) ─────────
                if (order.status == OrderStatus.pickedUp &&
                    order.otpCode != null) ...[
                  OtpHandoverWidget(
                    otpCode: order.otpCode!,
                    isRequester: true,
                  ),
                  const SizedBox(height: 24),
                ],

                // ─── Status Timeline ─────────────────────────────
                _StatusTimeline(order: order),

                // ─── SOS Button ──────────────────────────────────
                if (order.status.isActive) ...[
                  const SizedBox(height: 32),
                  const SosButton(),
                ],
                const SizedBox(height: 32),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            _statusLabel(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.requested:
        return AppColors.accentDark;
      case OrderStatus.accepted:
        return AppColors.primaryLight;
      case OrderStatus.pickedUp:
        return AppColors.primary;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _statusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.requested:
        return Icons.access_time_rounded;
      case OrderStatus.accepted:
        return Icons.handshake_rounded;
      case OrderStatus.pickedUp:
        return Icons.delivery_dining_rounded;
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.requested:
        return 'Finding Traveler...';
      case OrderStatus.accepted:
        return 'Traveler Assigned';
      case OrderStatus.pickedUp:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered ✓';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimaryLight)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow(this.label, this.value, {this.isBold = false});

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
                style: const TextStyle(
                    color: AppColors.textSecondaryLight, fontSize: 14)),
          ),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimaryLight,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  ))),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Timeline',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimaryLight)),
            ],
          ),
          const SizedBox(height: 20),
          _TimelineItem('Order Placed', order.createdAt, true, isFirst: true),
          if (order.status.index >= OrderStatus.accepted.index)
            _TimelineItem('Traveler Accepted', order.createdAt, true),
          if (order.pickupAt != null)
            _TimelineItem('Picked Up', order.pickupAt!, true),
          if (order.deliveredAt != null)
            _TimelineItem('Delivered', order.deliveredAt!, true, isLast: true),
          if (order.cancelledAt != null)
            _TimelineItem('Cancelled', order.cancelledAt!, true, isLast: true),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String label;
  final DateTime time;
  final bool completed;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem(this.label, this.time, this.completed,
      {this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              if (!isFirst)
                Container(
                    width: 2,
                    height: 16,
                    color:
                        completed ? AppColors.primary : AppColors.borderLight),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed ? AppColors.primary : AppColors.surfaceLight,
                  border: Border.all(
                      color:
                          completed ? AppColors.primary : AppColors.borderLight,
                      width: 2),
                ),
                child: completed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                    child: Container(
                        width: 2,
                        color: completed
                            ? AppColors.primary
                            : AppColors.borderLight)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                      child: Text(label,
                          style: TextStyle(
                            fontWeight:
                                completed ? FontWeight.w700 : FontWeight.w500,
                            color: completed
                                ? AppColors.textPrimaryLight
                                : AppColors.textSecondaryLight,
                            fontSize: 15,
                          ))),
                  Text(
                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
