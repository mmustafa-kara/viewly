class MovieModel {
  final int id;
  final String title;
  final String posterPath;
  final String overview;
  final double voteAverage;
  final String? backdropPath;
  final String? releaseDate;

  MovieModel({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.voteAverage,
    this.backdropPath,
    this.releaseDate,
  });

  /// Parse from TMDb JSON response
  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      posterPath: json['poster_path'] ?? '',
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      backdropPath: json['backdrop_path'],
      releaseDate: json['release_date'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'overview': overview,
      'vote_average': voteAverage,
      'backdrop_path': backdropPath,
      'release_date': releaseDate,
    };
  }

  /// Get full poster URL
  String get fullPosterPath {
    if (posterPath.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  /// Get full backdrop URL
  String get fullBackdropPath {
    if (backdropPath == null || backdropPath!.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/original$backdropPath';
  }
}
