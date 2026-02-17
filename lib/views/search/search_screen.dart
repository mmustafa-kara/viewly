import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../viewmodels/movie_viewmodel.dart';
import '../../widgets/movie_list_tile.dart';
import '../detail/movie_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(movieSearchProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Film veya dizi ara...',
            hintStyle: TextStyle(color: AppTheme.textHint),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            ref.read(movieSearchProvider.notifier).state = value;
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(movieSearchProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: searchQuery.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: AppTheme.textHint),
                  SizedBox(height: 16),
                  Text(
                    'Film veya dizi aramaya başlayın',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 16),
                  ),
                ],
              ),
            )
          : searchResults.when(
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
                          'Sonuç bulunamadı',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
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
    );
  }
}
