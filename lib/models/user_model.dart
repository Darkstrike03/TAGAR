class UserData {
  final String id;
  final String tagarId;
  final String? profileName;
  final String? username;
  final String? profilePicture;
  final String? bannerPicture;

  UserData({
    required this.id,
    required this.tagarId,
    this.profileName,
    this.username,
    this.profilePicture,
    this.bannerPicture,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as String,
      tagarId: json['tagar_id'] as String,
      profileName: json['profile_name'] as String?,
      username: json['username'] as String?,
      profilePicture: json['profile_picture'] as String?,
      bannerPicture: json['banner_picture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tagar_id': tagarId,
      'profile_name': profileName,
      'username': username,
      'profile_picture': profilePicture,
      'banner_picture': bannerPicture,
    };
  }
}
