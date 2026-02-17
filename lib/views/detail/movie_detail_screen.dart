import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/movie_model.dart';
import '../../core/theme.dart';
import '../../viewmodels/providers.dart';
import '../discussion/movie_discussions_screen.dart';

class MovieDetailScreen extends ConsumerWidget {
  final MovieModel movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Backdrop
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.background,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined, color: Colors.white),
                ),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop Image
                  CachedNetworkImage(
                    imageUrl: movie.fullBackdropPath.isNotEmpty
                        ? movie.fullBackdropPath
                        : movie.fullPosterPath,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: AppTheme.surface),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.surface,
                      child: const Icon(
                        Icons.movie_outlined,
                        color: AppTheme.textHint,
                        size: 64,
                      ),
                    ),
                  ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.background.withOpacity(0.7),
                          AppTheme.background,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    movie.title,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),

                  // Release Date (if available)
                  if (movie.releaseDate != null &&
                      movie.releaseDate!.isNotEmpty)
                    Text(
                      'Çıkış: ${movie.releaseDate}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 16),

                  // Rating and Action Buttons
                  Row(
                    children: [
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Share Button
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.bookmark_border),
                        color: AppTheme.textPrimary,
                        iconSize: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Overview Section
                  Text(
                    'Açıklama',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.overview.isNotEmpty
                        ? movie.overview
                        : 'Açıklama mevcut değil.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Discussion Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showCreatePostModal(context, ref, authState);
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Tartışma Başlat'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // View Discussions Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MovieDiscussionsScreen(movie: movie),
                          ),
                        );
                      },
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('Tartışmaları Gör'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePostModal(
    BuildContext context,
    WidgetRef ref,
    AsyncValue authState,
  ) {
    final user = authState.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tartışma başlatmak için giriş yapmalısınız'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Yeni Tartışma',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Movie Title
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.movie, size: 20, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        movie.title,
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Text Field
              TextField(
                controller: textController,
                maxLines: 5,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Düşüncelerini paylaş...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final content = textController.text.trim();

                    if (content.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen bir yorum yazın'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                      return;
                    }

                    try {
                      final firestoreService = ref.read(
                        firestoreServiceProvider,
                      );

                      await firestoreService.createPost(
                        userId: user.uid,
                        movieId: movie.id.toString(),
                        movieTitle: movie.title,
                        content: content,
                      );

                      Navigator.pop(modalContext);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tartışma başarıyla paylaşıldı! 🎉'),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Paylaş'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
