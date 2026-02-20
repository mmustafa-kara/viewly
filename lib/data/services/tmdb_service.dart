import 'package:dio/dio.dart';
import '../../core/config.dart';
import '../models/movie_model.dart';

class TMDbService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Config.tmdbBaseUrl,
      queryParameters: {'api_key': Config.tmdbApiKey, 'language': 'tr-TR'},
    ),
  );

  /// Get trending movies (today)
  Future<List<MovieModel>> getTrendingMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/trending/movie/day',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'];
        return results.map((json) => MovieModel.fromJson(json)).toList();
      } else {
        throw Exception('Film yüklenemedi');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get popular movies
  Future<List<MovieModel>> getPopularMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/movie/popular',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'];
        return results.map((json) => MovieModel.fromJson(json)).toList();
      } else {
        throw Exception('Film yüklenemedi');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Search movies and TV shows (multi search)
  Future<List<MovieModel>> searchMovies(String query) async {
    try {
      final response = await _dio.get(
        '/search/multi',
        queryParameters: {'query': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'];
        return results
            .where((json) => json['media_type'] != 'person')
            .map((json) => MovieModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Arama başarısız');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Discover movies/tv by genre
  Future<List<MovieModel>> discoverByGenre({
    required String mediaType, // 'movie' or 'tv'
    int? genreId,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'api_key': Config.tmdbApiKey,
        'language': 'tr-TR',
        'sort_by': 'popularity.desc',
        'page': page,
      };

      if (genreId != null) {
        queryParams['with_genres'] = genreId.toString();
      }

      final response = await _dio.get(
        '/discover/$mediaType',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'];
        return results.map((json) => MovieModel.fromJson(json)).toList();
      } else {
        throw Exception('Katalog yüklenemedi');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get movie details
  Future<MovieModel> getMovieDetails(int movieId) async {
    try {
      final response = await _dio.get('/movie/$movieId');

      if (response.statusCode == 200) {
        return MovieModel.fromJson(response.data);
      } else {
        throw Exception('Film detayları yüklenemedi');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors
  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Bağlantı zaman aşımına uğradı';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Sunucu yanıt vermedi';
    } else if (e.type == DioExceptionType.badResponse) {
      return 'Sunucu hatası: ${e.response?.statusCode}';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'İnternet bağlantısı yok';
    } else {
      return 'Bir hata oluştu: ${e.message}';
    }
  }
}
