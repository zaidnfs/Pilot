import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

/// Provides a stream of the current user's active orders (as requester).
final requesterOrdersProvider = StreamProvider<List<Order>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return SupabaseService.client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('requester_id', user.id)
      .order('created_at', ascending: false)
      .asyncMap((data) async {
        // Stream doesn't support inFilter, so we filter client-side
        final activeRows = data.where((row) =>
            ['requested', 'accepted', 'picked_up'].contains(row['status']));

        final futures = activeRows.map((row) => _expandOrder(
              row['id'],
              '*, stores(*), traveler:traveler_id(*)',
            ));

        final orders = await Future.wait(futures);
        return orders.whereType<Order>().toList();
      });
});

/// Provides a stream of available orders for travelers (status: requested).
final availableOrdersProvider = StreamProvider<List<Order>>((ref) {
  return SupabaseService.client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('status', 'requested')
      .order('created_at', ascending: false)
      .asyncMap((data) async {
        final futures = data.map((row) => _expandOrder(
              row['id'],
              '*, stores(*), requester:requester_id(*)',
            ));

        final orders = await Future.wait(futures);
        return orders.whereType<Order>().toList();
      });
});

/// Provides a stream of the current traveler's active delivery.
final travelerActiveOrderProvider = StreamProvider<Order?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return SupabaseService.client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('traveler_id', user.id)
      .asyncMap((data) async {
        // Stream doesn't support inFilter or limit, so we handle client-side
        final activeRow = data.where((row) =>
            ['accepted', 'picked_up'].contains(row['status'])).firstOrNull;

        if (activeRow == null) return null;

        return await _expandOrder(
          activeRow['id'],
          '*, stores(*), requester:requester_id(*)',
        );
      });
});

/// Provides a single order by ID (for tracking screen).
final orderByIdProvider = StreamProvider.family<Order?, int>((ref, orderId) {
  return SupabaseService.client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('id', orderId)
      .asyncMap((data) async {
        if (data.isEmpty) return null;
        return await _expandOrder(
          orderId,
          '*, stores(*), traveler:traveler_id(*), requester:requester_id(*)',
        );
      });
});

/// Helper to fetch joined data for a single order.
Future<Order?> _expandOrder(int orderId, String select) async {
  try {
    final expanded = await SupabaseService.client
        .from('orders')
        .select(select)
        .eq('id', orderId)
        .maybeSingle();

    if (expanded == null) return null;
    return Order.fromJson(expanded);
  } catch (e) {
    // Log error and return null to prevent stream crash
    return null;
  }
}

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
