import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../viewmodels/providers.dart';
import '../../discussion/post_detail_screen.dart';
import '../../detail/movie_detail_screen.dart';
import '../../../widgets/discussion_card.dart';
import '../../../data/models/post_model.dart';

class UserPostsTab extends ConsumerWidget {
  final AsyncValue<dynamic> userPosts;
  final String displayUsername;
  final String? currentUserId;
  final String effectiveUserId;

  const UserPostsTab({
    super.key,
    required this.userPosts,
    required this.displayUsername,
    required this.currentUserId,
    required this.effectiveUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return userPosts.when(
      data: (snapshot) {
        final posts = snapshot.docs;
        if (posts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: AppTheme.textHint,
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz tartışma yok',
                  style: TextStyle(color: AppTheme.textHint),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final doc = posts[index];
            final post = PostModel.fromFirestore(doc);

            return DiscussionCard(
              post: post,
              currentUserId: currentUserId,
              onUsernameTap: () {},
              onMovieTitleTap: () async {
                if (post.movieId.isNotEmpty) {
                  try {
                    final tmdbService = ref.read(tmdbServiceProvider);
                    final movieData = await tmdbService.getMovieDetails(
                      int.parse(post.movieId),
                    );
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieDetailScreen(movie: movieData),
                        ),
                      );
                    }
                  } catch (_) {}
                }
              },
              onCardTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: post),
                  ),
                );
              },
              onLikeTap: () async {
                if (currentUserId == null) return;
                final firestoreService = ref.read(firestoreServiceProvider);
                await firestoreService.toggleLike(post.id, currentUserId!);
              },
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Hata: $error',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
      ),
    );
  }
}
