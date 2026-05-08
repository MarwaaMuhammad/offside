class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String nationality;
  final String? profileImage;
  final String role; // 'player' or 'user'

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.nationality,
    this.profileImage,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String role) {
    return UserModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? json['player_id']?.toString() ?? '',
      name: json['name'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      nationality: json['nationality'] ?? '',
      profileImage: json['profile_image_url'] ?? json['image'] ?? '',
      role: role,
    );
  }
}
