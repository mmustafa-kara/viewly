import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration class to load environment variables
class Config {
  /// TMDb API Key
  static String get tmdbApiKey => dotenv.env['TMDB_API_KEY'] ?? '';

  /// TMDb API Base URL
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';

  /// TMDb Image Base URL
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/w500';
}
