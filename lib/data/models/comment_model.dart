import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String? id;
  final String? postId;
  final String authorId;
  final String authorUsername;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    this.id,
    this.postId,
    required this.authorId,
    required this.authorUsername,
    required this.content,
    required this.createdAt,
  });

  /// Parse from Firestore document
  factory CommentModel.fromFirestore(
    Map<String, dynamic> data,
    String docId, {
    String? postId,
  }) {
    return CommentModel(
      id: docId,
      postId: postId,
      authorId: data['authorId'] as String? ?? '',
      authorUsername: data['authorUsername'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      if (postId != null) 'postId': postId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
