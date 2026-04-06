/// Store model representing a merchant/kirana shop on the platform.
class Store {
  final int id;
  final String ownerId;
  final String name;
  final String? description;
  final String phone;
  final String address;
  final double lat;
  final double lng;
  final String category;
  final bool isActive;
  final DateTime createdAt;

  const Store({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.phone,
    required this.address,
    required this.lat,
    required this.lng,
    this.category = 'kirana',
    this.isActive = true,
    required this.createdAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: json['id'] as int,
        ownerId: json['owner_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        phone: json['phone'] as String,
        address: json['address'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        category: json['category'] as String? ?? 'kirana',
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'phone': phone,
        'address': address,
        'lat': lat,
        'lng': lng,
        'category': category,
        'is_active': isActive,
      };
}
