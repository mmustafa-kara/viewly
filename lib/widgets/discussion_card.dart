import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/post_model.dart';
import '../core/theme.dart';

/// A reusable discussion card widget with interactive elements.
class DiscussionCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onUsernameTap;
  final VoidCallback? onMovieTitleTap;
  final VoidCallback? onCardTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onDeleteTap;
  final String? currentUserId;

  const DiscussionCard({
    super.key,
    required this.post,
    this.onUsernameTap,
    this.onMovieTitleTap,
    this.onCardTap,
    this.onLikeTap,
    this.onDeleteTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final date = post.createdAt != null
        ? DateFormat('dd MMM yyyy').format(post.createdAt!)
        : '';

    return InkWell(
      onTap: onCardTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User & Movie Info Row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    post.authorUsername.isNotEmpty
                        ? post.authorUsername[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username (clickable)
                      InkWell(
                        onTap: onUsernameTap,
                        child: Text(
                          '@${post.authorUsername}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Movie title (clickable)
                      Row(
                        children: [
                          const Icon(
                            Icons.movie,
                            size: 14,
                            color: AppTheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: InkWell(
                              onTap: onMovieTitleTap,
                              child: Text(
                                post.movieTitle,
                                style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            date,
                            style: const TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (currentUserId == post.userId && onDeleteTap != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 22,
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 8),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Tartışmayı Sil'),
                          content: const Text(
                            'Bu tartışmayı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
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
                              onPressed: () {
                                Navigator.pop(dialogContext); // Close dialog
                                onDeleteTap!();
                              },
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Content
            Text(
              post.content,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Stats Row
            Row(
              children: [
                // Like button (interactive)
                InkWell(
                  onTap: onLikeTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.isLikedBy(currentUserId)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18,
                          color: post.isLikedBy(currentUserId)
                              ? AppTheme.error
                              : AppTheme.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likesCount}',
                          style: TextStyle(
                            color: post.isLikedBy(currentUserId)
                                ? AppTheme.error
                                : AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.comment_outlined,
                  size: 18,
                  color: AppTheme.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentsCount}',
                  style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
