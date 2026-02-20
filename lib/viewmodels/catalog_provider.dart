import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/movie_model.dart';
import '../data/services/tmdb_service.dart';
import 'providers.dart';

// Media type enum
enum MediaType { movie, tv }

class CatalogParams {
  final MediaType mediaType;
  final int? genreId;

  const CatalogParams({required this.mediaType, this.genreId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogParams &&
          runtimeType == other.runtimeType &&
          mediaType == other.mediaType &&
          genreId == other.genreId;

  @override
  int get hashCode => mediaType.hashCode ^ genreId.hashCode;
}

/// State class for Catalog
class CatalogState {
  final List<MovieModel> movies;
  final int currentPage;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final bool isInitialLoading;
  final String? errorMessage;

  const CatalogState({
    this.movies = const [],
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.isInitialLoading = false,
    this.errorMessage,
  });

  CatalogState copyWith({
    List<MovieModel>? movies,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasReachedMax,
    bool? isInitialLoading,
    String? errorMessage,
  }) {
    return CatalogState(
      movies: movies ?? this.movies,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      errorMessage: errorMessage,
    );
  }
}

/// StateNotifier for Catalog
class CatalogNotifier extends StateNotifier<CatalogState> {
  final TMDbService _tmdbService;
  final CatalogParams _params;

  CatalogNotifier(this._tmdbService, this._params)
    : super(const CatalogState(isInitialLoading: true)) {
    loadInitial();
  }

  /// Load initial data (page 1)
  Future<void> loadInitial() async {
    // If already loading initial, don't trigger again,
    // but here we might recommit to loading if params changed (handled by family provider)
    // or if we explicitly call it.

    // We update state to loading ONLY if not already loaded or if we want to show full spinner
    // But usually family provider recreation handles the "initial" state.
    // However, if we call refresh, we want to set isInitialLoading.

    // Let's just follow the simple pattern:
    state = state.copyWith(isInitialLoading: true, errorMessage: null);

    try {
      final movies = await _fetchMovies(page: 1);
      if (mounted) {
        state = state.copyWith(
          movies: movies,
          currentPage: 1,
          isInitialLoading: false,
          hasReachedMax: movies.isEmpty,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isInitialLoading: false,
          errorMessage: e.toString(),
        );
      }
    }
  }

  /// Load next page
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.hasReachedMax) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      // Artificial delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 500));

      final nextPage = state.currentPage + 1;
      final newMovies = await _fetchMovies(page: nextPage);

      if (mounted) {
        if (newMovies.isEmpty) {
          state = state.copyWith(isLoadingMore: false, hasReachedMax: true);
        } else {
          state = state.copyWith(
            movies: [...state.movies, ...newMovies],
            currentPage: nextPage,
            isLoadingMore: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: 'Yüklenirken hata oluştu',
        );
      }
    }
  }

  /// Refresh data (pull-to-refresh) - "Discovery" Mode
  Future<void> refreshData() async {
    // Generate a random page between 1 and 40 for "Discovery" experience
    final randomPage = Random().nextInt(40) + 1;

    // Set loading state (optional, or rely on RefreshIndicator)
    // We don't want to clear the list immediately if we want a smooth replace,
    // but typically refresh indicators expect a reload.
    // Let's keep isInitialLoading true to block interaction if needed,
    // or just let the UI handle the refresh spinner.
    // Given the requirement "fetch a random page... shuffle... update state",
    // we should validly replace the current list.

    try {
      final movies = await _fetchMovies(page: randomPage);

      // Shuffle results for "Discovery" feel
      movies.shuffle();

      if (mounted) {
        state = state.copyWith(
          movies: movies,
          currentPage: randomPage, // Next loadMore will be randomPage + 1
          isInitialLoading: false,
          hasReachedMax: movies.isEmpty,
          errorMessage: null,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          // Don't clear movies on error, just show toast/snackbar if we could,
          // but here we might just set error message
          errorMessage: 'Yenilenirken hata oluştu: $e',
        );
      }
    }
  }

  // Helper to fetch based on params
  Future<List<MovieModel>> _fetchMovies({required int page}) async {
    final mediaTypeString = _params.mediaType == MediaType.movie
        ? 'movie'
        : 'tv';

    return await _tmdbService.discoverByGenre(
      mediaType: mediaTypeString,
      genreId: _params.genreId,
      page: page,
    );
  }
}

/// Provider for selected genre
final selectedGenreProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Provider for CatalogNotifier
final catalogProvider = StateNotifierProvider.family
    .autoDispose<CatalogNotifier, CatalogState, CatalogParams>((ref, params) {
      final tmdbService = ref.watch(tmdbServiceProvider);
      return CatalogNotifier(tmdbService, params);
    });
