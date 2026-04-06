/// Immutable audit event for order state changes.
class OrderEvent {
  final int id;
  final int orderId;
  final String actorId;
  final String eventType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const OrderEvent({
    required this.id,
    required this.orderId,
    required this.actorId,
    required this.eventType,
    this.metadata = const {},
    required this.createdAt,
  });

  factory OrderEvent.fromJson(Map<String, dynamic> json) => OrderEvent(
        id: json['id'] as int,
        orderId: json['order_id'] as int,
        actorId: json['actor_id'] as String,
        eventType: json['event_type'] as String,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'actor_id': actorId,
        'event_type': eventType,
        'metadata': metadata,
      };
}
