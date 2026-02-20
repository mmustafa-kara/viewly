import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../viewmodels/catalog_provider.dart';
import '../../widgets/movie_card.dart';
import '../detail/movie_detail_screen.dart';

// No need to redeclare MediaType or CatalogParams or providers here
// They are imported from catalog_provider.dart

class CatalogScreen extends ConsumerStatefulWidget {
  final MediaType mediaType;

  const CatalogScreen({super.key, required this.mediaType});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Basic debounce could be added here if needed, but the provider guards against multiple calls
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final selectedGenre = ref.read(selectedGenreProvider);
      final params = CatalogParams(
        mediaType: widget.mediaType,
        genreId: selectedGenre,
      );

      // Trigger loadMore
      ref.read(catalogProvider(params).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedGenre = ref.watch(selectedGenreProvider);
    final params = CatalogParams(
      mediaType: widget.mediaType,
      genreId: selectedGenre,
    );

    final catalogState = ref.watch(catalogProvider(params));
    final notifier = ref.read(catalogProvider(params).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mediaType == MediaType.movie ? 'Filmler' : 'Diziler',
        ),
      ),
      body: Column(
        children: [
          // Genre Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _GenreChip(
                    label: 'Tümü',
                    isActive: selectedGenre == null,
                    onTap: () {
                      ref.read(selectedGenreProvider.notifier).state = null;
                      // Scroll to top when filter changes
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(0);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._getGenres(widget.mediaType).map(
                    (genre) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _GenreChip(
                        label: genre.name,
                        isActive: selectedGenre == genre.id,
                        onTap: () {
                          ref.read(selectedGenreProvider.notifier).state =
                              genre.id;
                          // Scroll to top when filter changes
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(0);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: catalogState.isInitialLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : catalogState.errorMessage != null &&
                      catalogState.movies.isEmpty
                ? Center(
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
                          'Hata: ${catalogState.errorMessage}',
                          style: const TextStyle(color: AppTheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => notifier.refreshData(),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                : catalogState.movies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.movie_filter_outlined,
                          size: 80,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.mediaType == MediaType.movie
                              ? 'Film bulunamadı'
                              : 'Dizi bulunamadı',
                          style: const TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: notifier.refreshData,
                    color: AppTheme.primary,
                    backgroundColor: AppTheme.surface,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return MovieCard(
                                movie: catalogState.movies[index],
                                width: double.infinity,
                                height: double.infinity,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MovieDetailScreen(
                                        movie: catalogState.movies[index],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }, childCount: catalogState.movies.length),
                          ),
                        ),
                        if (catalogState.isLoadingMore)
                          const SliverToBoxAdapter(
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _GenreChip({
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

// Genre data
class Genre {
  final int id;
  final String name;

  const Genre(this.id, this.name);
}

// TMDb Movie Genres
const List<Genre> _movieGenres = [
  Genre(28, 'Aksiyon'),
  Genre(35, 'Komedi'),
  Genre(18, 'Drama'),
  Genre(27, 'Korku'),
  Genre(10749, 'Romantik'),
  Genre(878, 'Bilim Kurgu'),
  Genre(53, 'Gerilim'),
  Genre(16, 'Animasyon'),
  Genre(99, 'Belgesel'),
  Genre(10751, 'Aile'),
];

// TMDb TV Show Genres (different IDs from movies!)
const List<Genre> _tvGenres = [
  Genre(10759, 'Aksiyon & Macera'),
  Genre(35, 'Komedi'),
  Genre(18, 'Dram'),
  Genre(10765, 'Bilim Kurgu & Fantastik'),
  Genre(9648, 'Gizem'),
  Genre(80, 'Suç'),
  Genre(16, 'Animasyon'),
  Genre(99, 'Belgesel'),
  Genre(10751, 'Aile'),
  Genre(10768, 'Savaş & Politik'),
];

List<Genre> _getGenres(MediaType mediaType) {
  return mediaType == MediaType.movie ? _movieGenres : _tvGenres;
}
