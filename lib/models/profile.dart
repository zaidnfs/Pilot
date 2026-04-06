/// Profile model representing a user on Dashauli Connect.
/// Every user is both a potential Requester and Traveler.
class Profile {
  final String id;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final String? upiId;
  final bool aadhaarVerified;
  final String? aadhaarMaskedName;
  final String? aadhaarPhotoUrl;
  final String activeMode; // 'requester' | 'traveler'
  final double? currentLat;
  final double? currentLng;
  final double? heading;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    this.upiId,
    this.aadhaarVerified = false,
    this.aadhaarMaskedName,
    this.aadhaarPhotoUrl,
    this.activeMode = 'requester',
    this.currentLat,
    this.currentLng,
    this.heading,
    this.isOnline = false,
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        phone: json['phone'] as String,
        avatarUrl: json['avatar_url'] as String?,
        upiId: json['upi_id'] as String?,
        aadhaarVerified: json['aadhaar_verified'] as bool? ?? false,
        aadhaarMaskedName: json['aadhaar_masked_name'] as String?,
        aadhaarPhotoUrl: json['aadhaar_photo_url'] as String?,
        activeMode: json['active_mode'] as String? ?? 'requester',
        currentLat: (json['current_lat'] as num?)?.toDouble(),
        currentLng: (json['current_lng'] as num?)?.toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        isOnline: json['is_online'] as bool? ?? false,
        lastSeenAt: json['last_seen_at'] != null
            ? DateTime.parse(json['last_seen_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'upi_id': upiId,
        'aadhaar_verified': aadhaarVerified,
        'aadhaar_masked_name': aadhaarMaskedName,
        'aadhaar_photo_url': aadhaarPhotoUrl,
        'active_mode': activeMode,
        'current_lat': currentLat,
        'current_lng': currentLng,
        'heading': heading,
        'is_online': isOnline,
        'last_seen_at': lastSeenAt?.toIso8601String(),
      };

  Profile copyWith({
    String? fullName,
    String? avatarUrl,
    String? upiId,
    bool? aadhaarVerified,
    String? aadhaarMaskedName,
    String? aadhaarPhotoUrl,
    String? activeMode,
    double? currentLat,
    double? currentLng,
    double? heading,
    bool? isOnline,
    DateTime? lastSeenAt,
  }) =>
      Profile(
        id: id,
        fullName: fullName ?? this.fullName,
        phone: phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        upiId: upiId ?? this.upiId,
        aadhaarVerified: aadhaarVerified ?? this.aadhaarVerified,
        aadhaarMaskedName: aadhaarMaskedName ?? this.aadhaarMaskedName,
        aadhaarPhotoUrl: aadhaarPhotoUrl ?? this.aadhaarPhotoUrl,
        activeMode: activeMode ?? this.activeMode,
        currentLat: currentLat ?? this.currentLat,
        currentLng: currentLng ?? this.currentLng,
        heading: heading ?? this.heading,
        isOnline: isOnline ?? this.isOnline,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
