class UserModel {
  final String uid;
  final String email;
  final String? username;
  final String? displayName;
  final String? photoUrl;
  final String? bio;
  final String? location;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.displayName,
    this.photoUrl,
    this.bio,
    this.location,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    required this.createdAt,
  });

  /// Fallback getter for legacy users who don't have a username yet.
  String get displayUsername {
    if (username != null && username!.isNotEmpty) {
      return username!;
    }
    return email.split('@').first;
  }

  /// Parse from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'],
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      location: data['location'],
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'location': location,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? location,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
