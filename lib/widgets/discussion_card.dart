import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

/// A reusable discussion card widget with interactive elements.
class DiscussionCard extends StatelessWidget {
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
  final VoidCallback? onUsernameTap;
  final VoidCallback? onMovieTitleTap;
  final VoidCallback? onCardTap;
  final VoidCallback? onLikeTap;

  const DiscussionCard({
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
    this.onUsernameTap,
    this.onMovieTitleTap,
    this.onCardTap,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = createdAt != null
        ? DateFormat('dd MMM yyyy').format(createdAt!)
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
                    authorUsername.isNotEmpty
                        ? authorUsername[0].toUpperCase()
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
                          '@$authorUsername',
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
                                movieTitle,
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
              ],
            ),
            const SizedBox(height: 12),

            // Content
            Text(
              content,
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
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isLiked ? AppTheme.error : AppTheme.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$likesCount',
                          style: TextStyle(
                            color: isLiked
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
                  '$commentsCount',
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
