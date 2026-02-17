import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/models/movie_model.dart';
import '../../viewmodels/user_viewmodel.dart';

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
              final post = posts[index].data() as Map<String, dynamic>;
              final timestamp = post['createdAt'];
              final date = timestamp != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate())
                  : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            (post['userName'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post['userName'] ?? 'Anonim',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                date,
                                style: const TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Post Content
                    Text(
                      post['content'] ?? '',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Actions
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_border, size: 20),
                          color: AppTheme.textHint,
                          onPressed: () {
                            // TODO: Like functionality
                          },
                        ),
                        Text(
                          '${post['likes'] ?? 0}',
                          style: const TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.comment_outlined, size: 20),
                          color: AppTheme.textHint,
                          onPressed: () {
                            // TODO: Comment functionality
                          },
                        ),
                        Text(
                          '${post['comments'] ?? 0}',
                          style: const TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
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
