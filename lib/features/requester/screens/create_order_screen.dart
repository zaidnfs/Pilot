import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/stores_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../services/supabase_service.dart';

/// Order creation screen for the Requester.
/// Select items, set bounty, choose delivery mode, and submit.
class CreateOrderScreen extends ConsumerStatefulWidget {
  final int storeId;

  const CreateOrderScreen({super.key, required this.storeId});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _itemsController = TextEditingController();
  final _costController = TextEditingController();
  final _bountyController = TextEditingController(text: '15');
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
      _showError('Minimum delivery bounty is ₹${AppConstants.minBounty.toInt()}');
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
      appBar: AppBar(title: const Text('New Order')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Store Info ────────────────────────────────────
              store.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Store not found'),
                data: (s) => s != null
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_rounded,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16)),
                                  Text(s.address,
                                      style: const TextStyle(fontSize: 13,
                                          color: AppColors.textSecondaryLight)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // ─── Items Description ─────────────────────────────
              Text('What do you need?',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _itemsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. 1 packet bread, 6 eggs, 1L milk',
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
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _costController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: '₹ ',
                            hintText: '100',
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
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bountyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: '₹ ',
                            hintText: '15',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Delivery Mode ─────────────────────────────────
              const Text('Delivery Mode',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      icon: Icons.schedule_rounded,
                      title: 'Standard',
                      subtitle: 'Wait for a passing Traveler',
                      isSelected: _deliveryMode == 'standard',
                      onTap: () =>
                          setState(() => _deliveryMode = 'standard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeCard(
                      icon: Icons.bolt_rounded,
                      title: 'Express',
                      subtitle: 'Wider broadcast, faster pickup',
                      isSelected: _deliveryMode == 'express',
                      onTap: () =>
                          setState(() => _deliveryMode = 'express'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ─── Submit ────────────────────────────────────────
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Place Order'),
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
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondaryLight),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : null,
                )),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }
}
