enum UserRole { client, provider }

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final UserRole role;
  final bool isKycVerified;
  final bool isAdmin;
  final bool isSuspended;
  final double rating;
  final int totalMissions;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.role = UserRole.client,
    this.isKycVerified = false,
    this.isAdmin = false,
    this.isSuspended = false,
    this.rating = 0.0,
    this.totalMissions = 0,
    required this.createdAt,
  });

  // ── Depuis Supabase ──────────────────────────────────
  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id:             map['id'] as String,
    fullName:       map['full_name'] as String,
    email:          map['email'] as String,
    avatarUrl:      map['avatar_url'] as String?,
    phone:          map['phone'] as String?,
    role:           map['role'] == 'provider'
        ? UserRole.provider
        : UserRole.client,
    isKycVerified:  map['is_kyc_verified'] as bool? ?? false,
    isAdmin: map['is_admin'] as bool? ?? false,
    isSuspended: map['is_suspended'] as bool? ?? false,
    rating:         (map['rating'] as num?)?.toDouble() ?? 0.0,
    totalMissions:  map['total_missions'] as int? ?? 0,
    createdAt:      DateTime.parse(map['created_at'] as String),
  );

  // ── Vers Supabase ────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'id':               id,
    'full_name':        fullName,
    'email':            email,
    'avatar_url':       avatarUrl,
    'phone':            phone,
    'role':             role == UserRole.provider ? 'provider' : 'client',
    'is_kyc_verified':  isKycVerified,
    'is_admin':         isAdmin,
    'is_suspended':     isSuspended,
    'rating':           rating,
    'total_missions':   totalMissions,
    'created_at':       createdAt.toIso8601String(),
  };

  // ── CopyWith ─────────────────────────────────────────
  AppUser copyWith({
    String? fullName,
    String? avatarUrl,
    String? phone,
    UserRole? role,
    bool? isKycVerified,
    double? rating,
    int? totalMissions,
  }) =>
      AppUser(
        id:            id,
        fullName:      fullName      ?? this.fullName,
        email:         email,
        avatarUrl:     avatarUrl     ?? this.avatarUrl,
        phone:         phone         ?? this.phone,
        role:          role          ?? this.role,
        isKycVerified: isKycVerified ?? this.isKycVerified,
        rating:        rating        ?? this.rating,
        totalMissions: totalMissions ?? this.totalMissions,
        createdAt:     createdAt,
      );

  // ── Helpers ──────────────────────────────────────────
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, 2).toUpperCase();
  }

  bool get isProvider => role == UserRole.provider;
}