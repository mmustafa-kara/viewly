import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/models/movie_model.dart';
import '../data/services/firestore_service.dart';
import 'providers.dart';

/// User Profile Provider
final userProfileProvider = FutureProvider.family<UserModel?, String>((
  ref,
  uid,
) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getUser(uid);
});

/// Current User Posts Provider
final userPostsProvider = StreamProvider.family((ref, String userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserPosts(userId);
});

/// Saved Movies Provider (Favorites)
final savedMoviesProvider = StreamProvider.family<List<MovieModel>, String>((
  ref,
  String userId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getFavoriteMovies(userId);
});

/// Liked Posts Provider
final likedPostsProvider = StreamProvider.family((ref, String userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getLikedPosts(userId);
});

/// All Posts Provider (Feed)
final allPostsProvider = StreamProvider((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllPosts();
});

/// Movie Posts Provider
final moviePostsProvider = StreamProvider.family((ref, String movieId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getMoviePosts(movieId);
});

// ========== FRIENDSHIP PROVIDERS ==========

/// Friend Count Provider
final friendCountProvider = StreamProvider.family<int, String>((
  ref,
  String userId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getFriendCount(userId);
});

/// Friends List Provider
final friendsListProvider = StreamProvider.family<List<UserModel>, String>((
  ref,
  String userId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getFriends(userId);
});

/// Incoming Requests Provider
final incomingRequestsProvider = StreamProvider.family<List<UserModel>, String>(
  (ref, String userId) {
    final firestoreService = ref.watch(firestoreServiceProvider);
    return firestoreService.getIncomingRequests(userId);
  },
);

class FriendshipArgs {
  final String currentUserId;
  final String targetUserId;

  FriendshipArgs({required this.currentUserId, required this.targetUserId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendshipArgs &&
          runtimeType == other.runtimeType &&
          currentUserId == other.currentUserId &&
          targetUserId == other.targetUserId;

  @override
  int get hashCode => currentUserId.hashCode ^ targetUserId.hashCode;
}

/// Friendship Status Provider
final friendshipStatusProvider =
    StreamProvider.family<FriendshipStatus, FriendshipArgs>((ref, args) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getFriendshipStatus(
        args.currentUserId,
        args.targetUserId,
      );
    });
