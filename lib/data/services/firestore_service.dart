import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/user_model.dart';
import '../models/movie_model.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

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

  /// Search users by username (starts with)
  Future<List<UserModel>> searchUsers(
    String query,
    String currentUserId,
  ) async {
    if (query.isEmpty) return [];

    // Firestore "starts with" query
    final snapshot = await _usersCollection
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .where((doc) => doc.id != currentUserId) // Exclude current user
        .map(
          (doc) => UserModel.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
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

  /// Get a single post data by its ID
  Future<PostModel?> getPostById(String postId) async {
    final doc = await _postsCollection.doc(postId).get();
    if (!doc.exists) return null;
    return PostModel.fromFirestore(doc);
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

  /// Edit a post
  Future<void> editPost(String postId, String newContent) async {
    await _firestore.collection('posts').doc(postId).update({
      'content': newContent,
    });
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  // The original deletePost method was here, but it's being replaced/modified by the instruction.
  // The instruction provided a partial line "/// Toggle Like on a Post _usersCollection.doc(userId).update({"
  // which seems to be a fragment and is not syntactically correct in this context.
  // Assuming the intent was to replace the old deletePost with the new one and add editPost.
  // The fragment is omitted to maintain syntactical correctness.

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
              .map(
                (doc) => CommentModel.fromFirestore(
                  doc.data(),
                  doc.id,
                  postId: doc.reference.parent.parent?.id,
                ),
              )
              .toList();
        });
  }
  // ========== FRIENDSHIP SYSTEM ==========

  /// Get the number of friends for a user
  Stream<int> getFriendCount(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('friends')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get a list of friends (UserModel) for a user
  Stream<List<UserModel>> getFriends(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) return [];

          final friendFutures = snapshot.docs.map((doc) async {
            final friendId = doc.id;
            final userDoc = await _usersCollection.doc(friendId).get();
            if (userDoc.exists) {
              return UserModel.fromFirestore(
                userDoc.data() as Map<String, dynamic>,
                userDoc.id,
              );
            }
            return null; // Return null if user data not found
          });

          final friendModels = await Future.wait(friendFutures);
          // Filter out nulls and return the list of valid friends
          return friendModels.whereType<UserModel>().toList();
        });
  }

  /// Get Friendship Status between two users
  Stream<FriendshipStatus> getFriendshipStatus(
    String currentUserId,
    String targetUserId,
  ) {
    final currentUserDocRef = _usersCollection.doc(currentUserId);

    // Stream to check if they are already friends
    final isFriendsStream = currentUserDocRef
        .collection('friends')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);

    // Stream to check if current user sent a request to target user
    final isRequestSentStream = currentUserDocRef
        .collection('sent_requests')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);

    // Stream to check if current user received a request from target user
    final isRequestReceivedStream = currentUserDocRef
        .collection('received_requests')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);

    return Rx.combineLatest3(
      isFriendsStream,
      isRequestSentStream,
      isRequestReceivedStream,
      (bool isFriends, bool isRequestSent, bool isRequestReceived) {
        if (isFriends) {
          return FriendshipStatus.friends;
        } else if (isRequestSent) {
          return FriendshipStatus.requestSent;
        } else if (isRequestReceived) {
          return FriendshipStatus.requestReceived;
        } else {
          return FriendshipStatus.notFriends;
        }
      },
    );
  }

  /// Send Friend Request
  Future<void> sendFriendRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    final batch = _firestore.batch();

    final currentUserSentRef = _usersCollection
        .doc(currentUserId)
        .collection('sent_requests')
        .doc(targetUserId);

    final targetUserReceivedRef = _usersCollection
        .doc(targetUserId)
        .collection('received_requests')
        .doc(currentUserId);

    batch.set(currentUserSentRef, {'timestamp': FieldValue.serverTimestamp()});
    batch.set(targetUserReceivedRef, {
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Cancel or Reject Friend Request
  Future<void> cancelFriendRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    final batch = _firestore.batch();

    final currentUserSentRef = _usersCollection
        .doc(currentUserId)
        .collection('sent_requests')
        .doc(targetUserId);

    final targetUserReceivedRef = _usersCollection
        .doc(targetUserId)
        .collection('received_requests')
        .doc(currentUserId);

    final currentUserReceivedRef = _usersCollection
        .doc(currentUserId)
        .collection('received_requests')
        .doc(targetUserId);

    final targetUserSentRef = _usersCollection
        .doc(targetUserId)
        .collection('sent_requests')
        .doc(currentUserId);

    // Try deleting all possible combinations to handle both cancel and reject scenarios using one method safely
    batch.delete(currentUserSentRef);
    batch.delete(targetUserReceivedRef);
    batch.delete(currentUserReceivedRef);
    batch.delete(targetUserSentRef);

    await batch.commit();
  }

  /// Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc(commentId);

    final batch = _firestore.batch();
    batch.delete(commentRef);
    batch.update(postRef, {
      'comments': FieldValue.increment(
        -1,
      ), // Changed 'commentCount' to 'comments' to match existing field
    });

    await batch.commit();
  }

  /// Get user's comments efficiently using a CollectionGroup query
  /// NOTE: This query requires a Composite Index in Firebase:
  /// Collection: comments
  /// Fields: authorId (Ascending) + createdAt (Descending)
  Future<List<CommentModel>> getUserComments(String userId) async {
    final snapshot = await _firestore
        .collectionGroup('comments')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => CommentModel.fromFirestore(
            doc.data(),
            doc.id,
            postId: doc.reference.parent.parent?.id,
          ),
        )
        .toList();
  }

  /// Get Incoming Friend Requests
  Stream<List<UserModel>> getIncomingRequests(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('received_requests')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          // Simulate network delay for modern UI loading state
          await Future.delayed(const Duration(milliseconds: 600));

          if (snapshot.docs.isEmpty) return [];

          final requestFutures = snapshot.docs.map((doc) async {
            final requesterId = doc.id;
            final userDoc = await _usersCollection.doc(requesterId).get();
            if (userDoc.exists) {
              return UserModel.fromFirestore(
                userDoc.data() as Map<String, dynamic>,
                userDoc.id,
              );
            }
            return null;
          });

          final requestModels = await Future.wait(requestFutures);
          return requestModels.whereType<UserModel>().toList();
        });
  }

  /// Accept Friend Request
  Future<void> acceptFriendRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    final batch = _firestore.batch();

    // 1. Add targetUserId to currentUserId's friends
    final currentFriendsRef = _usersCollection
        .doc(currentUserId)
        .collection('friends')
        .doc(targetUserId);
    batch.set(currentFriendsRef, {'addedAt': FieldValue.serverTimestamp()});

    // 2. Add currentUserId to targetUserId's friends
    final targetFriendsRef = _usersCollection
        .doc(targetUserId)
        .collection('friends')
        .doc(currentUserId);
    batch.set(targetFriendsRef, {'addedAt': FieldValue.serverTimestamp()});

    // 3. Remove from currentUserId's received_requests
    final currentUserReceivedRef = _usersCollection
        .doc(currentUserId)
        .collection('received_requests')
        .doc(targetUserId);
    batch.delete(currentUserReceivedRef);

    // 4. Remove from targetUserId's sent_requests
    final targetUserSentRef = _usersCollection
        .doc(targetUserId)
        .collection('sent_requests')
        .doc(currentUserId);
    batch.delete(targetUserSentRef);

    // Also remove any reverse requests just in case
    final currentUserSentRef = _usersCollection
        .doc(currentUserId)
        .collection('sent_requests')
        .doc(targetUserId);
    batch.delete(currentUserSentRef);

    final targetUserReceivedRef = _usersCollection
        .doc(targetUserId)
        .collection('received_requests')
        .doc(currentUserId);
    batch.delete(targetUserReceivedRef);

    await batch.commit();
  }

  /// Remove Friend
  Future<void> removeFriend(String currentUserId, String targetUserId) async {
    final batch = _firestore.batch();

    final currentToTargetRef = _usersCollection
        .doc(currentUserId)
        .collection('friends')
        .doc(targetUserId);

    final targetToCurrentRef = _usersCollection
        .doc(targetUserId)
        .collection('friends')
        .doc(currentUserId);

    batch.delete(currentToTargetRef);
    batch.delete(targetToCurrentRef);

    await batch.commit();
  }
}

enum FriendshipStatus { notFriends, requestSent, requestReceived, friends }
