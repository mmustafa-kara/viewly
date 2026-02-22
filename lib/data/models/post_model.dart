import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String authorUsername;
  final String movieId;
  final String movieTitle;
  final String content;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy;
  final DateTime? createdAt;

  const PostModel({
    required this.id,
    required this.userId,
    required this.authorUsername,
    required this.movieId,
    required this.movieTitle,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    required this.likedBy,
    this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return PostModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      authorUsername:
          data['authorUsername'] as String? ??
          data['userName'] as String? ??
          'Anonim',
      movieId: data['movieId'] as String? ?? '',
      movieTitle: data['movieTitle'] as String? ?? 'Film',
      content: data['content'] as String? ?? '',
      likesCount: data['likes'] as int? ?? 0,
      commentsCount: data['comments'] as int? ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Checks whether the post is liked by the specified user
  bool isLikedBy(String? currentUserId) {
    if (currentUserId == null) return false;
    return likedBy.contains(currentUserId);
  }
}
