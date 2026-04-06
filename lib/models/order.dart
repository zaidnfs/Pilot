import 'store.dart';
import 'profile.dart';

/// Order status enum mirroring the database CHECK constraint.
enum OrderStatus {
  requested,
  accepted,
  pickedUp,
  delivered,
  cancelled;

  String get value {
    switch (this) {
      case OrderStatus.requested:
        return 'requested';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static OrderStatus fromString(String s) {
    switch (s) {
      case 'requested':
        return OrderStatus.requested;
      case 'accepted':
        return OrderStatus.accepted;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        throw ArgumentError('Unknown order status: $s');
    }
  }

  bool get isActive =>
      this == OrderStatus.requested ||
      this == OrderStatus.accepted ||
      this == OrderStatus.pickedUp;
}

enum DeliveryMode {
  standard,
  express;

  String get value => name;
  static DeliveryMode fromString(String s) =>
      DeliveryMode.values.firstWhere((e) => e.name == s);
}

enum PaymentStatus {
  pending,
  sent,
  confirmed,
  disputed;

  String get value => name;
  static PaymentStatus fromString(String s) =>
      PaymentStatus.values.firstWhere((e) => e.name == s);
}

/// Order model representing a delivery request and its lifecycle.
class Order {
  final int id;
  final String requesterId;
  final String? travelerId;
  final int storeId;
  final OrderStatus status;
  final DeliveryMode deliveryMode;
  final String itemsDescription;
  final double itemsEstimatedCost;
  final double bounty;
  final String? otpCode;
  final bool otpVerified;
  final PaymentStatus paymentStatus;
  final String? upiTransactionId;
  final double requesterLat;
  final double requesterLng;
  final DateTime? pickupAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data (optional, from expanded queries)
  final Store? store;
  final Profile? traveler;
  final Profile? requester;

  const Order({
    required this.id,
    required this.requesterId,
    this.travelerId,
    required this.storeId,
    this.status = OrderStatus.requested,
    this.deliveryMode = DeliveryMode.standard,
    required this.itemsDescription,
    required this.itemsEstimatedCost,
    required this.bounty,
    this.otpCode,
    this.otpVerified = false,
    this.paymentStatus = PaymentStatus.pending,
    this.upiTransactionId,
    required this.requesterLat,
    required this.requesterLng,
    this.pickupAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancelReason,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.store,
    this.traveler,
    this.requester,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int,
        requesterId: json['requester_id'] as String,
        travelerId: json['traveler_id'] as String?,
        storeId: json['store_id'] as int,
        status: OrderStatus.fromString(json['status'] as String),
        deliveryMode: DeliveryMode.fromString(json['delivery_mode'] as String),
        itemsDescription: json['items_description'] as String,
        itemsEstimatedCost: (json['items_estimated_cost'] as num).toDouble(),
        bounty: (json['bounty'] as num).toDouble(),
        otpCode: json['otp_code'] as String?,
        otpVerified: json['otp_verified'] as bool? ?? false,
        paymentStatus:
            PaymentStatus.fromString(json['payment_status'] as String),
        upiTransactionId: json['upi_transaction_id'] as String?,
        requesterLat: (json['requester_lat'] as num).toDouble(),
        requesterLng: (json['requester_lng'] as num).toDouble(),
        pickupAt: json['pickup_at'] != null
            ? DateTime.parse(json['pickup_at'] as String)
            : null,
        deliveredAt: json['delivered_at'] != null
            ? DateTime.parse(json['delivered_at'] as String)
            : null,
        cancelledAt: json['cancelled_at'] != null
            ? DateTime.parse(json['cancelled_at'] as String)
            : null,
        cancelReason: json['cancel_reason'] as String?,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        store: json['stores'] != null
            ? Store.fromJson(json['stores'] as Map<String, dynamic>)
            : null,
        traveler: json['traveler'] != null
            ? Profile.fromJson(json['traveler'] as Map<String, dynamic>)
            : null,
        requester: json['requester'] != null
            ? Profile.fromJson(json['requester'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'requester_id': requesterId,
        'store_id': storeId,
        'delivery_mode': deliveryMode.value,
        'items_description': itemsDescription,
        'items_estimated_cost': itemsEstimatedCost,
        'bounty': bounty,
        'requester_lat': requesterLat,
        'requester_lng': requesterLng,
        'expires_at': expiresAt?.toIso8601String(),
      };

  double get totalCost => itemsEstimatedCost + bounty;

  bool get isAvailable => status == OrderStatus.requested && travelerId == null;
}
