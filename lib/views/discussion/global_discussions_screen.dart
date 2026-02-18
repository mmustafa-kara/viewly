import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../viewmodels/providers.dart';
import '../../widgets/discussion_card.dart';
import '../profile/profile_screen.dart';
import '../detail/movie_detail_screen.dart';
import 'create_post_bottom_sheet.dart';

// Provider for top-rated discussions (sorted by likes)
final topRatedDiscussionsProvider = StreamProvider.autoDispose((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getTopRatedPosts();
});

class GlobalDiscussionsScreen extends ConsumerWidget {
  const GlobalDiscussionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discussions = ref.watch(topRatedDiscussionsProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popüler Tartışmalar',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'En çok beğenilen film yorumları',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: 'Tümü', isActive: true, onTap: () {}),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Bu Hafta',
                      isActive: false,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Bu Ay', isActive: false, onTap: () {}),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Discussions List
            Expanded(
              child: discussions.when(
                data: (snapshot) {
                  final posts = snapshot.docs;

                  if (posts.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 80,
                            color: AppTheme.textHint,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Henüz tartışma yok',
                            style: TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'İlk yorumu sen yap!',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final doc = posts[index];
                      final post = doc.data() as Map<String, dynamic>;
                      final postId = doc.id;

                      final userId = post['userId'] as String? ?? '';
                      final authorUsername =
                          post['authorUsername'] as String? ?? '';
                      final movieId = post['movieId'] as String? ?? '';
                      final movieTitle =
                          post['movieTitle'] as String? ?? 'Film';
                      final content = post['content'] as String? ?? '';
                      final likesCount = post['likes'] as int? ?? 0;
                      final commentsCount = post['comments'] as int? ?? 0;
                      final likedBy = List<String>.from(post['likedBy'] ?? []);
                      final isLiked =
                          currentUserId != null &&
                          likedBy.contains(currentUserId);

                      final timestamp = post['createdAt'];
                      final createdAt = timestamp != null
                          ? timestamp.toDate() as DateTime
                          : null;

                      return DiscussionCard(
                        postId: postId,
                        userId: userId,
                        authorUsername: authorUsername.isNotEmpty
                            ? authorUsername
                            : userId.isNotEmpty
                            ? userId.substring(
                                0,
                                userId.length > 6 ? 6 : userId.length,
                              )
                            : 'anonim',
                        movieId: movieId,
                        movieTitle: movieTitle,
                        content: content,
                        likesCount: likesCount,
                        commentsCount: commentsCount,
                        isLiked: isLiked,
                        createdAt: createdAt,
                        onUsernameTap: () {
                          if (userId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(userId: userId),
                              ),
                            );
                          }
                        },
                        onMovieTitleTap: () async {
                          if (movieId.isNotEmpty) {
                            try {
                              final tmdbService = ref.read(tmdbServiceProvider);
                              final movieData = await tmdbService
                                  .getMovieDetails(int.parse(movieId));
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MovieDetailScreen(movie: movieData),
                                  ),
                                );
                              }
                            } catch (_) {
                              // Silently ignore if movie cannot be fetched
                            }
                          }
                        },
                        onCardTap: () {
                          // TODO: Navigate to PostDetailScreen (placeholder)
                        },
                        onLikeTap: () async {
                          if (currentUserId == null) return;
                          final firestoreService = ref.read(
                            firestoreServiceProvider,
                          );
                          await firestoreService.toggleLike(
                            postId,
                            currentUserId,
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hata: $error',
                        style: const TextStyle(color: AppTheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Global Post FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const CreatePostBottomSheet(),
          );
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
