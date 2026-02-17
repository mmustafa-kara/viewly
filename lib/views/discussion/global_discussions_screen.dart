import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../viewmodels/providers.dart';

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

            // Filter chips (placeholder for future)
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
                      final post = posts[index].data() as Map<String, dynamic>;
                      final timestamp = post['createdAt'];
                      final date = timestamp != null
                          ? DateFormat('dd MMM yyyy').format(timestamp.toDate())
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
                            // User & Movie Info
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.primary,
                                  child: Text(
                                    (post['userId'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.movie,
                                            size: 14,
                                            color: AppTheme.secondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              post['movieTitle'] ?? 'Film',
                                              style: const TextStyle(
                                                color: AppTheme.secondary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
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

                            // Content
                            Text(
                              post['content'] ?? '',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                height: 1.5,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),

                            // Stats
                            Row(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  size: 18,
                                  color: AppTheme.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post['likes'] ?? 0}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.comment_outlined,
                                  size: 18,
                                  color: AppTheme.textHint,
                                ),
                                const SizedBox(width: 4),
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
              : AppTheme.primary.withOpacity(0.15),
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
