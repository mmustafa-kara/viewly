import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/auth_service.dart';
import '../data/services/tmdb_service.dart';
import '../data/services/firestore_service.dart';
import '../data/models/comment_model.dart';

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// TMDb Service Provider
final tmdbServiceProvider = Provider<TMDbService>((ref) {
  return TMDbService();
});

/// Firestore Service Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Auth State Provider
final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// User Comments Provider
final userCommentsProvider = FutureProvider.family<List<CommentModel>, String>((
  ref,
  userId,
) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserComments(userId);
});
