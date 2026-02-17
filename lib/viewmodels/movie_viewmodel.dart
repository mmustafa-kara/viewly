import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/movie_model.dart';
import 'providers.dart';

/// Trending Movies Provider
final trendingMoviesProvider = FutureProvider<List<MovieModel>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return await tmdbService.getTrendingMovies();
});

/// Popular Movies Provider
final popularMoviesProvider = FutureProvider<List<MovieModel>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return await tmdbService.getPopularMovies();
});

/// Movie Search Provider
final movieSearchProvider = StateProvider<String>((ref) => '');

/// Search Results Provider
final searchResultsProvider = FutureProvider<List<MovieModel>>((ref) async {
  final query = ref.watch(movieSearchProvider);

  if (query.isEmpty) {
    return [];
  }

  final tmdbService = ref.watch(tmdbServiceProvider);
  return await tmdbService.searchMovies(query);
});
