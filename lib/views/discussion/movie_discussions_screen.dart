import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/models/movie_model.dart';
import '../../data/models/post_model.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/providers.dart';
import '../../widgets/discussion_card.dart';
import '../profile/profile_screen.dart';
import 'post_detail_screen.dart';

class MovieDiscussionsScreen extends ConsumerWidget {
  final MovieModel movie;

  const MovieDiscussionsScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviePosts = ref.watch(moviePostsProvider(movie.id.toString()));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tartışmalar', style: TextStyle(fontSize: 18)),
            Text(
              movie.title,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.secondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: moviePosts.when(
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
                    style: TextStyle(color: AppTheme.textHint, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'İlk tartışmayı sen başlat!',
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
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final doc = posts[index];
              final post = PostModel.fromFirestore(doc);
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DiscussionCard(
                  post: post,
                  currentUserId: currentUserId,
                  onUsernameTap: () {
                    if (post.userId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfileScreen(visitedUserId: post.userId),
                        ),
                      );
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
                    await firestoreService.toggleLike(post.id, currentUserId);
                  },
                ),
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
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
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
    );
  }
}
