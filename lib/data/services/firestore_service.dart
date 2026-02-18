import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/movie_model.dart';
import '../models/comment_model.dart';

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
    required String authorUsername,
    required String movieId,
    required String movieTitle,
    required String content,
  }) async {
    try {
      await _postsCollection.add({
        'userId': userId,
        'authorUsername': authorUsername,
        'movieId': movieId,
        'movieTitle': movieTitle,
        'content': content,
        'likes': 0,
        'likedBy': <String>[],
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

  /// Get posts with dynamic filters (time + sort)
  Stream<QuerySnapshot> getFilteredPosts({
    DateTime? timeCutoff,
    required String sortField, // 'likes' or 'createdAt'
  }) {
    Query query = _postsCollection;

    if (timeCutoff != null) {
      // When filtering by time, Firestore requires orderBy on the inequality field first
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: timeCutoff)
          .orderBy('createdAt', descending: true);
    } else if (sortField == 'likes') {
      // Top rated without time filter → exclude 0-likes posts
      query = query
          .where('likes', isGreaterThan: 0)
          .orderBy('likes', descending: true);
    } else {
      // Newest without time filter
      query = query.orderBy(sortField, descending: true);
    }

    return query.limit(50).snapshots();
  }

  /// Toggle like on a post (Twitter-style: add/remove userId from likedBy array)
  Future<void> toggleLike(String postId, String currentUserId) async {
    try {
      final doc = await _postsCollection.doc(postId).get();
      final data = doc.data() as Map<String, dynamic>?;
      final likedBy = List<String>.from(data?['likedBy'] ?? []);

      if (likedBy.contains(currentUserId)) {
        // Unlike
        await _postsCollection.doc(postId).update({
          'likedBy': FieldValue.arrayRemove([currentUserId]),
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Like
        await _postsCollection.doc(postId).update({
          'likedBy': FieldValue.arrayUnion([currentUserId]),
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      throw Exception('Beğeni güncellenemedi: $e');
    }
  }

  /// Get posts liked by a specific user
  Stream<QuerySnapshot> getLikedPosts(String userId) {
    return _postsCollection
        .where('likedBy', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ========== FAVORITES SYSTEM (NO orderBy) ==========

  /// Toggle favorite status for a movie
  Future<void> toggleFavoriteMovie(String userId, MovieModel movie) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(movie.id.toString());

    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'movieId': movie.id,
        'title': movie.title,
        'posterPath': movie.posterPath,
        'voteAverage': movie.voteAverage,
      });
    }
  }

  /// Check if a movie is in user's favorites
  Future<bool> isMovieFavorite(String userId, String movieId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(movieId)
        .get();
    return doc.exists;
  }

  /// Get stream of user's favorite movies (NO orderBy)
  Stream<List<MovieModel>> getFavoriteMovies(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return MovieModel(
              id: data['movieId'] as int,
              title: data['title'] as String,
              overview: '',
              posterPath: data['posterPath'] as String? ?? '',
              voteAverage: (data['voteAverage'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();
        });
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

  // ========== COMMENTS SYSTEM ==========

  /// Add a comment to a post (batch: add comment + increment commentCount)
  Future<void> addComment(String postId, CommentModel comment) async {
    try {
      final batch = _firestore.batch();

      // 1. Add comment document to subcollection
      final commentRef = _postsCollection
          .doc(postId)
          .collection('comments')
          .doc();
      batch.set(commentRef, comment.toFirestore());

      // 2. Increment comment count on parent post
      batch.update(_postsCollection.doc(postId), {
        'comments': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Yorum eklenemedi: $e');
    }
  }

  /// Stream comments for a post (oldest first)
  Stream<List<CommentModel>> getComments(String postId) {
    return _postsCollection
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }
}
