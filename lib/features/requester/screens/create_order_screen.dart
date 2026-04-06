import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/upi_generator.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/stores_provider.dart';
import '../../../services/supabase_service.dart';

/// Screen to create a new delivery request (Order).
/// Requester enters items, estimated cost, and delivery bounty.
class CreateOrderScreen extends ConsumerStatefulWidget {
  final int storeId;

  const CreateOrderScreen({super.key, required this.storeId});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _itemsController = TextEditingController();
  final _costController = TextEditingController();
  final _bountyController = TextEditingController();
  String _deliveryMode = 'standard';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _itemsController.dispose();
    _costController.dispose();
    _bountyController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final items = _itemsController.text.trim();
    final cost = double.tryParse(_costController.text.trim());
    final bounty = double.tryParse(_bountyController.text.trim());

    if (items.isEmpty) {
      _showError('Please describe what you need');
      return;
    }
    if (cost == null || cost <= 0) {
      _showError('Please enter the estimated cost');
      return;
    }
    if (bounty == null || bounty < AppConstants.minBounty) {
      _showError(
          'Minimum delivery bounty is ₹${AppConstants.minBounty.toInt()}');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get current location
      final position = await ref.read(currentPositionProvider.future);
      if (position == null) {
        _showError('Location permission required');
        return;
      }

      final expiry = _deliveryMode == 'express'
          ? AppConstants.orderExpiryExpress
          : AppConstants.orderExpiryStandard;

      final order = await ref.read(orderActionsProvider.notifier).createOrder({
        'requester_id': SupabaseService.currentUserId,
        'store_id': widget.storeId,
        'delivery_mode': _deliveryMode,
        'items_description': items,
        'items_estimated_cost': cost,
        'bounty': bounty,
        'requester_lat': position.latitude,
        'requester_lng': position.longitude,
        'expires_at': DateTime.now().add(expiry).toUtc().toIso8601String(),
      });

      if (order != null && mounted) {
        // Mock UPI intent generation check before navigation
        final upiLink = UpiGenerator.generateUpiLink(
          payeeAddress: 'dashauli@upi',
          payeeName: 'Dashauli Connect',
          amount: cost + bounty,
          transactionNote: 'Order #${order.id}',
        );
        print('Ready to pay with: $upiLink'); // Just for demonstration

        context.pushReplacementNamed('trackOrder',
            pathParameters: {'orderId': order.id.toString()});
      }
    } catch (e) {
      _showError('Failed to create order: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeByIdProvider(widget.storeId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('New Order'),
        backgroundColor: AppColors.backgroundLight,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Store Info ────────────────────────────────────
              store.when(
                loading: () =>
                    const LinearProgressIndicator(color: AppColors.primary),
                error: (_, __) => const Text('Store not found'),
                data: (s) => s != null
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accentLight.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.storefront_rounded,
                                  color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: AppColors.textPrimaryLight)),
                                  const SizedBox(height: 4),
                                  Text(s.address,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondaryLight)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),

              // ─── Items Description ─────────────────────────────
              Text('What do you need?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight)),
              const SizedBox(height: 12),
              TextField(
                controller: _itemsController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'e.g. 1 packet bread, 6 eggs, 1L milk',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Cost & Bounty ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimated Cost',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryLight)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _costController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                fontSize: 18),
                            hintText: '0',
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivery Bounty',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryLight)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bountyController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                                fontSize: 18),
                            hintText: '15',
                            filled: true,
                            fillColor: AppColors.surfaceLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ─── Delivery Mode ─────────────────────────────────
              const Text('Delivery Speed',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimaryLight)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      icon: Icons.schedule_rounded,
                      title: 'Standard',
                      subtitle: 'Wait for a passing Traveler',
                      isSelected: _deliveryMode == 'standard',
                      onTap: () => setState(() => _deliveryMode = 'standard'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ModeCard(
                      icon: Icons.bolt_rounded,
                      title: 'Express',
                      subtitle: 'Wider broadcast, faster pickup',
                      isSelected: _deliveryMode == 'express',
                      onTap: () => setState(() => _deliveryMode = 'express'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // ─── Submit ────────────────────────────────────────
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Pay via UPI & Request',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentLight.withOpacity(0.3)
              : AppColors.surfaceLight,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondaryLight,
                size: 28),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondaryLight,
                )),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? AppColors.textPrimaryLight
                        : AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }
}
