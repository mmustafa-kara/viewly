import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../viewmodels/providers.dart';
import '../../viewmodels/discussion_filter_provider.dart';
import '../../widgets/discussion_card.dart';
import '../profile/profile_screen.dart';
import '../detail/movie_detail_screen.dart';
import 'create_post_bottom_sheet.dart';
import 'post_detail_screen.dart';

/// Filtered discussions provider — rebuilds when filter state changes
final filteredDiscussionsProvider = StreamProvider.autoDispose((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final filterState = ref.watch(discussionFilterProvider);

  final sortField = filterState.sortFilter == SortFilter.topRated
      ? 'likes'
      : 'createdAt';

  return firestoreService.getFilteredPosts(
    timeCutoff: filterState.timeCutoff,
    sortField: sortField,
  );
});

class GlobalDiscussionsScreen extends ConsumerWidget {
  const GlobalDiscussionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discussions = ref.watch(filteredDiscussionsProvider);
    final filterState = ref.watch(discussionFilterProvider);
    final filterNotifier = ref.read(discussionFilterProvider.notifier);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popüler Tartışmalar',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSubtitle(filterState),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) => filterNotifier.setSearchQuery(value),
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Film adına göre ara...',
                  hintStyle: const TextStyle(color: AppTheme.textHint),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.textHint,
                  ),
                  suffixIcon: filterState.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppTheme.textHint,
                          ),
                          onPressed: () => filterNotifier.setSearchQuery(''),
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // ── Time Filters ──
                    _FilterChip(
                      label: 'Tümü',
                      isActive: filterState.timeFilter == TimeFilter.all,
                      onTap: () => filterNotifier.setTimeFilter(TimeFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Bu Hafta',
                      isActive: filterState.timeFilter == TimeFilter.thisWeek,
                      onTap: () =>
                          filterNotifier.setTimeFilter(TimeFilter.thisWeek),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Bu Ay',
                      isActive: filterState.timeFilter == TimeFilter.thisMonth,
                      onTap: () =>
                          filterNotifier.setTimeFilter(TimeFilter.thisMonth),
                    ),

                    const SizedBox(width: 16),
                    // Divider between filter groups
                    Container(
                      width: 1,
                      height: 24,
                      color: AppTheme.textHint.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 16),

                    // ── Sort Filters ──
                    _FilterChip(
                      label: 'En Çok Beğenilen',
                      icon: Icons.favorite,
                      isActive: filterState.sortFilter == SortFilter.topRated,
                      onTap: () =>
                          filterNotifier.setSortFilter(SortFilter.topRated),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'En Yeni',
                      icon: Icons.schedule,
                      isActive: filterState.sortFilter == SortFilter.newest,
                      onTap: () =>
                          filterNotifier.setSortFilter(SortFilter.newest),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Discussions List
            Expanded(
              child: discussions.when(
                data: (snapshot) {
                  var posts = snapshot.docs;

                  // Client-side sort for time-filtered + topRated combo
                  if (filterState.timeCutoff != null &&
                      filterState.sortFilter == SortFilter.topRated) {
                    posts = List.from(posts)
                      ..sort((a, b) {
                        final aLikes =
                            (a.data() as Map<String, dynamic>)['likes']
                                as int? ??
                            0;
                        final bLikes =
                            (b.data() as Map<String, dynamic>)['likes']
                                as int? ??
                            0;
                        return bLikes.compareTo(aLikes);
                      });
                  }

                  // Client-side search filter by movieTitle
                  final searchQuery = filterState.searchQuery.toLowerCase();
                  if (searchQuery.isNotEmpty) {
                    posts = posts.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final movieTitle = (data['movieTitle'] as String? ?? '')
                          .toLowerCase();
                      return movieTitle.contains(searchQuery);
                    }).toList();
                  }

                  if (posts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            searchQuery.isNotEmpty
                                ? Icons.search_off
                                : Icons.forum_outlined,
                            size: 80,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'Bu aramayla eşleşen tartışma bulunamadı'
                                : filterState.timeFilter == TimeFilter.all
                                ? 'Henüz tartışma yok'
                                : 'Bu dönemde tartışma yok',
                            style: const TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'İlk yorumu sen yap!',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
                                builder: (_) =>
                                    ProfileScreen(visitedUserId: userId),
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
                            } catch (_) {}
                          }
                        },
                        onCardTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(
                                postId: postId,
                                userId: userId,
                                authorUsername: authorUsername.isNotEmpty
                                    ? authorUsername
                                    : 'anonim',
                                movieId: movieId,
                                movieTitle: movieTitle,
                                content: content,
                                likesCount: likesCount,
                                commentsCount: commentsCount,
                                isLiked: isLiked,
                                createdAt: createdAt,
                              ),
                            ),
                          );
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

  String _getSubtitle(DiscussionFilterState state) {
    final time = switch (state.timeFilter) {
      TimeFilter.all => 'Tüm zamanlar',
      TimeFilter.thisWeek => 'Bu hafta',
      TimeFilter.thisMonth => 'Bu ay',
    };
    final sort = switch (state.sortFilter) {
      SortFilter.topRated => 'en çok beğenilen',
      SortFilter.newest => 'en yeni',
    };
    return '$time · $sort';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isActive ? Colors.white : AppTheme.primary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
