import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../data/models/comment_model.dart';
import '../../viewmodels/providers.dart';
import '../../widgets/discussion_card.dart';
import '../profile/profile_screen.dart';
import '../detail/movie_detail_screen.dart';

/// Stream provider for comments on a specific post
final commentsProvider = StreamProvider.family<List<CommentModel>, String>((
  ref,
  postId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getComments(postId);
});

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  final String userId;
  final String authorUsername;
  final String movieId;
  final String movieTitle;
  final String content;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime? createdAt;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.userId,
    required this.authorUsername,
    required this.movieId,
    required this.movieTitle,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    this.createdAt,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isSending = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      // Get current user's username
      final userData = await firestoreService.getUser(currentUser.uid);
      final username = userData?.username ?? 'anonim';

      final comment = CommentModel(
        authorId: currentUser.uid,
        authorUsername: username,
        content: text,
        createdAt: DateTime.now(), // serverTimestamp used in toFirestore
      );

      await firestoreService.addComment(widget.postId, comment);

      if (mounted) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum gönderilemedi: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.postId));
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tartışma Detayı'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Original Post (expanded content, no card tap)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Original post card (non-tappable)
                DiscussionCard(
                  postId: widget.postId,
                  userId: widget.userId,
                  authorUsername: widget.authorUsername,
                  movieId: widget.movieId,
                  movieTitle: widget.movieTitle,
                  content: widget.content,
                  likesCount: widget.likesCount,
                  commentsCount: widget.commentsCount,
                  isLiked: widget.isLiked,
                  createdAt: widget.createdAt,
                  onCardTap: null, // Don't navigate to self
                  onUsernameTap: () {
                    if (widget.userId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfileScreen(visitedUserId: widget.userId),
                        ),
                      );
                    }
                  },
                  onMovieTitleTap: () async {
                    if (widget.movieId.isNotEmpty) {
                      try {
                        final tmdbService = ref.read(tmdbServiceProvider);
                        final movieData = await tmdbService.getMovieDetails(
                          int.parse(widget.movieId),
                        );
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MovieDetailScreen(movie: movieData),
                            ),
                          );
                        }
                      } catch (_) {}
                    }
                  },
                  onLikeTap: () async {
                    if (currentUserId == null) return;
                    final firestoreService = ref.read(firestoreServiceProvider);
                    await firestoreService.toggleLike(
                      widget.postId,
                      currentUserId,
                    );
                  },
                  onDeleteTap: () async {
                    if (currentUserId == null) return;
                    final firestoreService = ref.read(firestoreServiceProvider);
                    try {
                      await firestoreService.deletePost(widget.postId);
                      if (context.mounted) {
                        Navigator.pop(
                          context,
                        ); // Go back after deleting the post
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tartışma silindi')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                      }
                    }
                  },
                  currentUserId: currentUserId,
                ),

                // Divider
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppTheme.textHint, height: 1),
                ),

                // Comments Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Yorumlar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Comments List
                comments.when(
                  data: (commentList) {
                    if (commentList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: AppTheme.textHint,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Henüz yorum yok',
                                style: TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'İlk yorumu sen yap!',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: commentList
                          .map(
                            (comment) => _CommentTile(
                              comment: comment,
                              currentUserId: currentUserId ?? '',
                              postId: widget.postId,
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'Yorumlar yüklenemedi',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reply Input Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: AppTheme.cardBackground,
                border: Border(
                  top: BorderSide(color: AppTheme.surface, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Yanıtını yaz...',
                        hintStyle: const TextStyle(color: AppTheme.textHint),
                        filled: true,
                        fillColor: AppTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendComment,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual comment tile widget
class _CommentTile extends ConsumerWidget {
  final CommentModel comment;
  final String currentUserId;
  final String postId;

  const _CommentTile({
    required this.comment,
    required this.currentUserId,
    required this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.secondary,
                child: Text(
                  comment.authorUsername.isNotEmpty
                      ? comment.authorUsername[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '@${comment.authorUsername}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(comment.createdAt),
                style: const TextStyle(color: AppTheme.textHint, fontSize: 11),
              ),
            ],
          ),
          // Actions
          if (currentUserId == comment.authorId)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Yorumu Sil'),
                      content: const Text(
                        'Bu yorumu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(dialogContext); // Close dialog

                            try {
                              final firestoreService = ref.read(
                                firestoreServiceProvider,
                              );
                              await firestoreService.deleteComment(
                                postId,
                                comment.id ?? '',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Yorum silindi'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Yorum silinemedi: $e'),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Sil'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          // Content
          Text(
            comment.content,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
    if (diff.inHours < 24) return '${diff.inHours}sa';
    if (diff.inDays < 7) return '${diff.inDays}g';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
