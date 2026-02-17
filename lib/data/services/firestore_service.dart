import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Users collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Posts collection reference
  CollectionReference get _postsCollection => _firestore.collection('posts');

  /// Create or update user in Firestore
  Future<void> saveUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toFirestore());
    } catch (e) {
      throw Exception('Kullanıcı kaydedilemedi: $e');
    }
  }

  /// Get user by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı yüklenemedi: $e');
    }
  }

  /// Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      throw Exception('Profil güncellenemedi: $e');
    }
  }

  /// Create a new post
  Future<void> createPost({
    required String userId,
    required String movieId,
    required String movieTitle,
    required String content,
  }) async {
    try {
      await _postsCollection.add({
        'userId': userId,
        'movieId': movieId,
        'movieTitle': movieTitle,
        'content': content,
        'likes': 0,
        'comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment user's posts count
      await _usersCollection.doc(userId).update({
        'postsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Gönderi oluşturulamadı: $e');
    }
  }

  /// Get posts for a specific movie
  Stream<QuerySnapshot> getMoviePosts(String movieId) {
    return _postsCollection
        .where('movieId', isEqualTo: movieId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get posts from a specific user
  Stream<QuerySnapshot> getUserPosts(String userId) {
    return _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get all posts (for feed)
  Stream<QuerySnapshot> getAllPosts() {
    return _postsCollection
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Get top-rated posts (sorted by likes)
  Stream<QuerySnapshot> getTopRatedPosts() {
    return _postsCollection
        .orderBy('likes', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Like a post
  Future<void> likePost(String postId) async {
    try {
      await _postsCollection.doc(postId).update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Beğeni eklenemedi: $e');
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId, String userId) async {
    try {
      await _postsCollection.doc(postId).delete();

      // Decrement user's posts count
      await _usersCollection.doc(userId).update({
        'postsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Gönderi silinemedi: $e');
    }
  }
}
