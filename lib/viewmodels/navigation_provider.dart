import 'package:flutter_riverpod/flutter_riverpod.dart';

// Bottom Navigation Index Provider
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// Category Toggle Provider (Movies vs Series)
enum MediaCategory { movies, series }

final mediaCategoryProvider = StateProvider<MediaCategory>(
  (ref) => MediaCategory.series,
);
