import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
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
