class Contact {
  final String id;
  final String userId;
  final String contactUserId;
  final String contactTagarId;
  final String? displayName;
  final String? profileName;
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.userId,
    required this.contactUserId,
    required this.contactTagarId,
    this.displayName,
    this.profileName,
    required this.createdAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contactUserId: json['contact_user_id'] as String,
      contactTagarId: json['contact_tagar_id'] as String,
      displayName: json['display_name'] as String?,
      profileName: json['profile_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromTagarId;
  final String status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromTagarId,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      fromTagarId: json['from_tagar_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
