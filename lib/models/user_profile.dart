class UserProfile {
  final String name;
  final String phone;
  final String email;
  final String? profilePicBase64;
  final String? localPhotoPath;
  final bool isGuest;

  UserProfile({
    required this.name,
    required this.phone,
    required this.email,
    this.profilePicBase64,
    this.localPhotoPath,
    this.isGuest = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'profilePicBase64': profilePicBase64 ?? '',
      'localPhotoPath': localPhotoPath ?? '',
      'isGuest': isGuest,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      profilePicBase64: json['profilePicBase64'],
      localPhotoPath: json['localPhotoPath'],
      isGuest: json['isGuest'] ?? false,
    );
  }
}

