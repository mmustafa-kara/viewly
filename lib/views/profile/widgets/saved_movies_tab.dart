import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/models/movie_model.dart';
import '../../detail/movie_detail_screen.dart';
import '../../../widgets/movie_card.dart';

class SavedMoviesTab extends StatelessWidget {
  final AsyncValue<List<MovieModel>> savedMovies;

  const SavedMoviesTab({super.key, required this.savedMovies});

  @override
  Widget build(BuildContext context) {
    return savedMovies.when(
      data: (movies) {
        if (movies.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.bookmark_border, size: 64, color: AppTheme.textHint),
                SizedBox(height: 16),
                Text(
                  'Henüz kaydedilen film yok',
                  style: TextStyle(color: AppTheme.textHint),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
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
                    builder: (_) => MovieDetailScreen(movie: movies[index]),
                  ),
                );
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
