import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/movie_list_tile.dart';
import '../../viewmodels/movie_viewmodel.dart';
import '../../viewmodels/navigation_provider.dart';
import '../detail/movie_detail_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingMovies = ref.watch(trendingMoviesProvider);
    final popularMovies = ref.watch(popularMoviesProvider);
    final selectedCategory = ref.watch(mediaCategoryProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keşfet',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Binlerce film ve tartışma seni bekliyor',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {},
                      color: AppTheme.textPrimary,
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomSearchBar(
                  hintText: 'Film veya dizi ara...',
                  readOnly: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Categories (Diziler / Filmler buttons)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _CategoryButton(
                      icon: Icons.movie_outlined,
                      label: 'Diziler',
                      subtitle: 'En yeni bölümler',
                      isActive: selectedCategory == MediaCategory.series,
                      onTap: () {
                        ref.read(mediaCategoryProvider.notifier).state =
                            MediaCategory.series;
                      },
                    ),
                    const SizedBox(width: 12),
                    _CategoryButton(
                      icon: Icons.live_tv,
                      label: 'Filmler',
                      subtitle: 'Vizyondakiler',
                      isActive: selectedCategory == MediaCategory.movies,
                      onTap: () {
                        ref.read(mediaCategoryProvider.notifier).state =
                            MediaCategory.movies;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Trending Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedCategory == MediaCategory.series
                          ? 'Trend Diziler'
                          : 'Trend Filmler',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Tümünü Gör',
                        style: TextStyle(color: AppTheme.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Trending Movies Horizontal List
            SliverToBoxAdapter(
              child: SizedBox(
                height: 210,
                child: trendingMovies.when(
                  data: (movies) {
                    if (movies.isEmpty) {
                      return const Center(
                        child: Text(
                          'Henüz film yok',
                          style: TextStyle(color: AppTheme.textHint),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        return MovieCard(
                          movie: movies[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MovieDetailScreen(movie: movies[index]),
                              ),
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
                        const SizedBox(height: 8),
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
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Popular Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trend Filmler',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Tümünü Gör',
                        style: TextStyle(color: AppTheme.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Popular Movies Vertical List
            popularMovies.when(
              data: (movies) {
                if (movies.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Henüz film yok',
                          style: TextStyle(color: AppTheme.textHint),
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return MovieListTile(
                        movie: movies[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MovieDetailScreen(movie: movies[index]),
                            ),
                          );
                        },
                      );
                    }, childCount: movies.length > 10 ? 10 : movies.length),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
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
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary.withOpacity(0.15)
                : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: AppTheme.primary, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
