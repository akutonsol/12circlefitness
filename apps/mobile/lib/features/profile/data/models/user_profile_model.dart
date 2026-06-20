class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final String role;
  final String? fitnessGoal;
  final double? heightCm;
  final double? weightKg;
  final String? phone;
  final String membershipTier;
  final String coachingMode;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.fitnessGoal,
    this.heightCm,
    this.weightKg,
    this.phone,
    required this.membershipTier,
    this.coachingMode = 'self_guided',
  });

  String get fullName => "$firstName $lastName".trim();
  String get displayName => firstName.isNotEmpty ? firstName : email.split("@").first;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json["id"] as String,
      firstName: json["first_name"] as String? ?? "",
      lastName: json["last_name"] as String? ?? "",
      email: json["email"] as String? ?? "",
      avatarUrl: json["avatar_url"] as String?,
      role: json["role"] as String? ?? "client",
      fitnessGoal: json["fitness_goal"] as String?,
      heightCm: (json["height_cm"] as num?)?.toDouble(),
      weightKg: (json["weight_kg"] as num?)?.toDouble(),
      phone: json["phone"] as String?,
      membershipTier: json["membership_tier"] as String? ?? "basic",
      coachingMode: json["coaching_mode"] as String? ?? "self_guided",
    );
  }

  Map<String, dynamic> toJson() => {
    "first_name": firstName,
    "last_name": lastName,
    "email": email,
    "avatar_url": avatarUrl,
    "role": role,
    "fitness_goal": fitnessGoal,
    "height_cm": heightCm,
    "weight_kg": weightKg,
    "phone": phone,
    "membership_tier": membershipTier,
    "coaching_mode": coachingMode,
  };

  UserProfile copyWith({
    String? firstName, String? lastName, String? email,
    String? avatarUrl, String? role, String? fitnessGoal,
    double? heightCm, double? weightKg, String? phone,
    String? membershipTier, String? coachingMode,
  }) => UserProfile(
    id: id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    role: role ?? this.role,
    fitnessGoal: fitnessGoal ?? this.fitnessGoal,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    phone: phone ?? this.phone,
    membershipTier: membershipTier ?? this.membershipTier,
    coachingMode: coachingMode ?? this.coachingMode,
  );
}
