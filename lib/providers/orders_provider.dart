import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../services/supabase_service.dart';

import '../core/dummy_data.dart';

/// Provides a stream of the current user's active orders (as requester).
final requesterOrdersProvider =
    StreamProvider<List<Order>>((ref) {
  // TEMP: Return dummy data
  return Stream.value([DummyData.trackingOrder]);
});

/// Provides a stream of available orders for travelers (status: requested).
final availableOrdersProvider =
    StreamProvider<List<Order>>((ref) {
  // TEMP: Return dummy data
  return Stream.value(DummyData.availableOrders);
});

/// Provides a stream of the current traveler's active delivery.
final travelerActiveOrderProvider =
    StreamProvider<Order?>((ref) {
  // TEMP: Return dummy data
  return Stream.value(DummyData.activeDelivery);
});

/// Provides a single order by ID (for tracking screen).
final orderByIdProvider =
    StreamProvider.family<Order?, int>((ref, orderId) {
  // TEMP: Return dummy data
  return Stream.value(DummyData.trackingOrder);
});

/// Order operations (accept, pickup, cancel).
class OrderActionsNotifier extends StateNotifier<AsyncValue<void>> {
  OrderActionsNotifier() : super(const AsyncValue.data(null));

  /// Create a new delivery order.
  Future<Order?> createOrder(Map<String, dynamic> orderData) async {
    state = const AsyncValue.loading();
    try {
      final response = await SupabaseService.client
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      // Generate OTP for the order
      final orderId = response['id'] as int;
      await SupabaseService.client.rpc('generate_order_otp', params: {
        'p_order_id': orderId,
        'p_requester_id': SupabaseService.currentUserId,
      });

      state = const AsyncValue.data(null);
      return Order.fromJson(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Traveler accepts an order.
  Future<bool> acceptOrder(int orderId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.from('orders').update({
        'traveler_id': SupabaseService.currentUserId,
        'status': 'accepted',
      }).eq('id', orderId);

      await _logEvent(orderId, 'accepted');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Traveler marks items as picked up from store.
  Future<bool> markPickedUp(int orderId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.from('orders').update({
        'status': 'picked_up',
        'pickup_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', orderId);

      await _logEvent(orderId, 'picked_up');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Cancel an order.
  Future<bool> cancelOrder(int orderId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.from('orders').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toUtc().toIso8601String(),
        'cancel_reason': reason,
      }).eq('id', orderId);

      await _logEvent(orderId, 'cancelled', {'reason': reason});
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Verify OTP for delivery completion (called by Traveler).
  Future<bool> verifyDeliveryOtp(int orderId, String otp) async {
    state = const AsyncValue.loading();
    try {
      final result = await SupabaseService.client.rpc(
        'verify_delivery_otp',
        params: {
          'p_order_id': orderId,
          'p_traveler_id': SupabaseService.currentUserId,
          'p_otp': otp,
        },
      );

      state = const AsyncValue.data(null);
      return result as bool;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> _logEvent(
    int orderId,
    String eventType, [
    Map<String, dynamic>? metadata,
  ]) async {
    await SupabaseService.client.from('order_events').insert({
      'order_id': orderId,
      'actor_id': SupabaseService.currentUserId,
      'event_type': eventType,
      'metadata': metadata ?? {},
    });
  }
}

final orderActionsProvider =
    StateNotifierProvider<OrderActionsNotifier, AsyncValue<void>>((ref) {
  return OrderActionsNotifier();
});
