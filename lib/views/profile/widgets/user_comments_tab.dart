import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../viewmodels/providers.dart';
import '../../discussion/post_detail_screen.dart';

class UserCommentsTab extends ConsumerWidget {
  final String userId;

  const UserCommentsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) return const SizedBox.shrink();

    final commentsAsync = ref.watch(userCommentsProvider(userId));

    return commentsAsync.when(
      data: (comments) {
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 48,
                    color: AppTheme.textHint,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Henüz hiç yorum yapmadınız.',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];

            String dateStr = '';
            try {
              final now = DateTime.now();
              final diff = now.difference(comment.createdAt);
              if (diff.inMinutes < 1) {
                dateStr = 'az önce';
              } else if (diff.inMinutes < 60) {
                dateStr = '${diff.inMinutes}dk';
              } else if (diff.inHours < 24) {
                dateStr = '${diff.inHours}sa';
              } else if (diff.inDays < 7) {
                dateStr = '${diff.inDays}g';
              } else {
                dateStr =
                    '${comment.createdAt.day}/${comment.createdAt.month}/${comment.createdAt.year}';
              }
            } catch (_) {}

            return Card(
              color: AppTheme.surface,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                onTap: () => _handleCommentTap(context, ref, comment.postId),
                leading: const Icon(
                  Icons.comment_rounded,
                  color: AppTheme.primary,
                  size: 24,
                ),
                title: Text(
                  comment.content,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    dateStr,
                    style: const TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
      error: (error, _) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'Yorumlar yüklenirken bir hata oluştu.',
            style: TextStyle(color: AppTheme.error),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCommentTap(
    BuildContext context,
    WidgetRef ref,
    String? postId,
  ) async {
    if (postId == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final postData = await firestoreService.getPostById(postId);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (postData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: postData)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu tartışma silinmiş veya artık mevcut değil.'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tartışmaya gidilirken bir hata oluştu.'),
          ),
        );
      }
    }
  }
}
