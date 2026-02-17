import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/models/movie_model.dart';
import '../../viewmodels/providers.dart';
import '../../widgets/movie_card.dart';
import '../detail/movie_detail_screen.dart';

// Media type enum
enum MediaType { movie, tv }

// State provider for selected genre
final selectedGenreProvider = StateProvider.autoDispose<int?>((ref) => null);

// Provider for catalog movies/tv based on filters
final catalogMoviesProvider = FutureProvider.autoDispose
    .family<List<MovieModel>, CatalogParams>((ref, params) async {
      final tmdbService = ref.watch(tmdbServiceProvider);
      final selectedGenre = ref.watch(selectedGenreProvider);

      // Convert MediaType enum to string for API
      final mediaTypeString = params.mediaType == MediaType.movie
          ? 'movie'
          : 'tv';

      // Use discover endpoint with genre filter
      return await tmdbService.discoverByGenre(
        mediaType: mediaTypeString,
        genreId: selectedGenre,
      );
    });

class CatalogParams {
  final MediaType mediaType;

  const CatalogParams({required this.mediaType});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogParams &&
          runtimeType == other.runtimeType &&
          mediaType == other.mediaType;

  @override
  int get hashCode => mediaType.hashCode;
}

class CatalogScreen extends ConsumerWidget {
  final MediaType mediaType;

  const CatalogScreen({super.key, required this.mediaType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogMovies = ref.watch(
      catalogMoviesProvider(CatalogParams(mediaType: mediaType)),
    );
    final selectedGenre = ref.watch(selectedGenreProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(mediaType == MediaType.movie ? 'Filmler' : 'Diziler'),
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
                    genreId: null,
                    isActive: selectedGenre == null,
                    onTap: () {
                      ref.read(selectedGenreProvider.notifier).state = null;
                    },
                  ),
                  const SizedBox(width: 8),
                  ...genres.map(
                    (genre) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _GenreChip(
                        label: genre.name,
                        genreId: genre.id,
                        isActive: selectedGenre == genre.id,
                        onTap: () {
                          ref.read(selectedGenreProvider.notifier).state =
                              genre.id;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Movies Grid
          Expanded(
            child: catalogMovies.when(
              data: (movies) {
                if (movies.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie_filter_outlined,
                          size: 80,
                          color: AppTheme.textHint,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Film bulunamadı',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    return MovieCard(
                      movie: movies[index],
                      width: double.infinity,
                      height: double.infinity,
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
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  final int? genreId;
  final bool isActive;
  final VoidCallback onTap;

  const _GenreChip({
    required this.label,
    required this.genreId,
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

// Genre data
class Genre {
  final int id;
  final String name;

  const Genre(this.id, this.name);
}

const List<Genre> genres = [
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
