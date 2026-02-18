import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/models/movie_model.dart';
import '../../viewmodels/providers.dart';

/// A 2-step bottom sheet: Step 1 = Movie Search, Step 2 = Compose Post.
class CreatePostBottomSheet extends ConsumerStatefulWidget {
  const CreatePostBottomSheet({super.key});

  @override
  ConsumerState<CreatePostBottomSheet> createState() =>
      _CreatePostBottomSheetState();
}

class _CreatePostBottomSheetState extends ConsumerState<CreatePostBottomSheet> {
  final _searchController = TextEditingController();
  final _contentController = TextEditingController();

  List<MovieModel> _searchResults = [];
  bool _isSearching = false;
  MovieModel? _selectedMovie;
  bool _isPosting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _searchMovies(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final tmdbService = ref.read(tmdbServiceProvider);
      final results = await tmdbService.searchMovies(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _handlePost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty || _selectedMovie == null) return;

    setState(() {
      _isPosting = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authStateProvider).value;
      if (authState == null) throw 'Giriş yapmalısınız.';

      final firestoreService = ref.read(firestoreServiceProvider);

      // Fetch user profile for authorUsername
      final userProfile = await firestoreService.getUser(authState.uid);
      final authorUsername =
          userProfile?.displayUsername ??
          authState.email?.split('@').first ??
          'anonim';

      await firestoreService.createPost(
        userId: authState.uid,
        authorUsername: authorUsername,
        movieId: _selectedMovie!.id.toString(),
        movieTitle: _selectedMovie!.title,
        content: content,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gönderi başarıyla paylaşıldı! 🎉'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedMovie == null ? 'Film Seç' : 'Gönderi Oluştur',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (_selectedMovie != null)
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppTheme.textPrimary,
                        ),
                        onPressed: () {
                          setState(() => _selectedMovie = null);
                        },
                      )
                    else
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
              ),

              const Divider(color: AppTheme.cardBackground, height: 1),

              // Content
              Expanded(
                child: _selectedMovie == null
                    ? _buildSearchStep(scrollController)
                    : _buildComposeStep(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Step 1: Search and pick a movie
  Widget _buildSearchStep(ScrollController scrollController) {
    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Film ara...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => _searchMovies(value),
          ),
        ),

        // Results
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'Hakkında yorum yapmak istediğin filmi ara'
                        : 'Sonuç bulunamadı',
                    style: const TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final movie = _searchResults[index];
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedMovie = movie);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // Poster
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: movie.fullPosterPath.isNotEmpty
                                  ? Image.network(
                                      movie.fullPosterPath,
                                      width: 45,
                                      height: 65,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 45,
                                        height: 65,
                                        color: AppTheme.surface,
                                        child: const Icon(
                                          Icons.movie_outlined,
                                          color: AppTheme.textHint,
                                          size: 24,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 45,
                                      height: 65,
                                      color: AppTheme.surface,
                                      child: const Icon(
                                        Icons.movie_outlined,
                                        color: AppTheme.textHint,
                                        size: 24,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            // Title + year
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie.title,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (movie.releaseDate != null &&
                                      movie.releaseDate!.length >= 4)
                                    Text(
                                      movie.releaseDate!.substring(0, 4),
                                      style: const TextStyle(
                                        color: AppTheme.textHint,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Rating
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  movie.voteAverage.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Step 2: Compose the post
  Widget _buildComposeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected movie info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.movie, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hakkında konuşuluyor:',
                        style: TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _selectedMovie!.title,
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content text field
          TextField(
            controller: _contentController,
            maxLines: 6,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Düşüncelerini paylaş...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.error, fontSize: 14),
              ),
            ),

          // Share button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isPosting ? null : _handlePost,
              icon: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isPosting ? 'Paylaşılıyor...' : 'Paylaş'),
            ),
          ),
        ],
      ),
    );
  }
}
