import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/app_strings.dart';
import '../../data/services/firestore_service.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/providers.dart';
import '../../widgets/discussion_card.dart';
import '../main_wrapper.dart';
import '../auth/login_screen.dart';
import '../detail/movie_detail_screen.dart';
import '../discussion/post_detail_screen.dart';
import '../../data/models/post_model.dart';
import 'friends_screen.dart';
import 'user_search_screen.dart';
import 'friend_requests_screen.dart';
import 'widgets/user_posts_tab.dart';
import 'widgets/user_comments_tab.dart';
import 'widgets/saved_movies_tab.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? visitedUserId;

  const ProfileScreen({super.key, this.visitedUserId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTabIndex = 0;

  String get _effectiveUserId =>
      widget.visitedUserId ?? FirebaseAuth.instance.currentUser!.uid;

  bool get _isRootTab => widget.visitedUserId == null;

  /// Determine if the current auth user is the owner of this profile
  bool get _isOwner {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == _effectiveUserId;
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider(_effectiveUserId));
    final userPosts = ref.watch(userPostsProvider(_effectiveUserId));
    final savedMovies = ref.watch(savedMoviesProvider(_effectiveUserId));
    final likedPosts = ref.watch(likedPostsProvider(_effectiveUserId));
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final friendCountAsync = ref.watch(friendCountProvider(_effectiveUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileTitle),
        leading: _isRootTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: AppStrings.backTooltip,
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (!_isRootTab)
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: AppStrings.homeTooltip,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainWrapper()),
                  (route) => false,
                );
              },
            ),
          if (_isOwner) ...[
            Consumer(
              builder: (context, ref, child) {
                final requestsAsync = ref.watch(
                  incomingRequestsProvider(_effectiveUserId),
                );

                return requestsAsync.when(
                  data: (requests) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications),
                          tooltip: AppStrings.friendRequestsTooltip,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FriendRequestsScreen(
                                  userId: _effectiveUserId,
                                ),
                              ),
                            );
                          },
                        ),
                        if (requests.isNotEmpty)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${requests.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FriendRequestsScreen(userId: _effectiveUserId),
                        ),
                      );
                    },
                  ),
                  error: (_, _) => IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FriendRequestsScreen(userId: _effectiveUserId),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'logout') {
                  final authService = ref.read(authServiceProvider);
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } else if (value == 'delete') {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(AppStrings.deleteAccountTitle),
                        ],
                      ),
                      content: Text(
                        AppStrings.deleteAccountWarning,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(AppStrings.cancelButton),
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

                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              final authService = ref.read(authServiceProvider);
                              await authService.deleteAccount();

                              if (context.mounted) {
                                Navigator.pop(
                                  context,
                                ); // Close loading indicator
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(
                                  context,
                                ); // Close loading indicator
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                          child: Text(AppStrings.deleteButton),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 20),
                      const SizedBox(width: 12),
                      Text(AppStrings.logoutButton),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_forever,
                        size: 20,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.deleteAccountButton,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: userProfile.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                AppStrings.userNotFound,
                style: const TextStyle(color: AppTheme.textHint),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),

                // Profile Avatar
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 16),

                // Username
                Text(
                  '@${user.displayUsername}',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),

                // Bio
                if (user.bio != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      user.bio!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // Location
                if (user.location != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppTheme.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.location!,
                        style: const TextStyle(color: AppTheme.textHint),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // Stats
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FriendsScreen(userId: _effectiveUserId),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: _StatItem(
                            label: AppStrings.friendsCount,
                            value: friendCountAsync.when(
                              // ignore: avoid_types_as_parameter_types
                              data: (count) => _formatNumber(count),
                              loading: () => '...',
                              error: (_, _) => '-',
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        // ignore: deprecated_member_use
                        color: AppTheme.textHint.withOpacity(0.2),
                      ),
                      _StatItem(
                        label: AppStrings.discussionsCount,
                        value: _formatNumber(user.postsCount),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Button (Owner: Arkadaş Bul, Visitor: Dynamic Friendship Button)
                if (currentUserId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _isOwner
                        ? Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.person_search),
                              label: Text(
                                AppStrings.findFriendsBtn,
                                textAlign: TextAlign.center,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UserSearchScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        : _buildFriendshipButton(
                            currentUserId,
                            _effectiveUserId,
                            ref,
                          ),
                  ),

                const SizedBox(height: 20),

                // Tabs
                Column(
                  children: [
                    // Tab Headers
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _TabButton(
                            label: _isOwner
                                ? AppStrings.myDiscussionsTab
                                : AppStrings.tabDiscussions,
                            isActive: _selectedTabIndex == 0,
                            onTap: () => setState(() => _selectedTabIndex = 0),
                          ),
                          _TabButton(
                            label: AppStrings.tabSaved,
                            isActive: _selectedTabIndex == 1,
                            onTap: () => setState(() => _selectedTabIndex = 1),
                          ),
                          _TabButton(
                            label: AppStrings.tabLiked,
                            isActive: _selectedTabIndex == 2,
                            onTap: () => setState(() => _selectedTabIndex = 2),
                          ),
                          _TabButton(
                            label: AppStrings.tabComments,
                            isActive: _selectedTabIndex == 3,
                            onTap: () => setState(() => _selectedTabIndex = 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ===== Tab Content =====
                    if (_selectedTabIndex == 0)
                      UserPostsTab(
                        userPosts: userPosts,
                        displayUsername: user.displayUsername,
                        currentUserId: currentUserId,
                        effectiveUserId: _effectiveUserId,
                      )
                    else if (_selectedTabIndex == 1)
                      SavedMoviesTab(savedMovies: savedMovies)
                    else if (_selectedTabIndex == 2)
                      _buildLikedPostsTab(likedPosts, currentUserId)
                    else
                      UserCommentsTab(userId: _effectiveUserId),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                '${AppStrings.loadingError} $error',
                style: const TextStyle(color: AppTheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Tab 3: Liked Posts =====
  Widget _buildLikedPostsTab(AsyncValue likedPosts, String? currentUserId) {
    return likedPosts.when(
      data: (snapshot) {
        final posts = snapshot.docs;
        if (posts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.favorite_border, size: 64, color: AppTheme.textHint),
                SizedBox(height: 16),
                Text(
                  AppStrings.emptyLiked,
                  style: TextStyle(color: AppTheme.textHint),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final doc = posts[index];
            final post = PostModel.fromFirestore(doc);

            return DiscussionCard(
              post: post,
              currentUserId: currentUserId,
              onUsernameTap: () {
                if (post.userId.isNotEmpty && post.userId != _effectiveUserId) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(visitedUserId: post.userId),
                    ),
                  );
                }
              },
              onMovieTitleTap: () async {
                if (post.movieId.isNotEmpty) {
                  try {
                    final tmdbService = ref.read(tmdbServiceProvider);
                    final movieData = await tmdbService.getMovieDetails(
                      int.parse(post.movieId),
                    );
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieDetailScreen(movie: movieData),
                        ),
                      );
                    }
                  } catch (_) {}
                }
              },
              onCardTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: post),
                  ),
                );
              },
              onLikeTap: () async {
                if (currentUserId == null) return;
                final firestoreService = ref.read(firestoreServiceProvider);
                await firestoreService.toggleLike(post.id, currentUserId);
              },
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Hata: $error',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendshipButton(
    String currentUserId,
    String targetUserId,
    WidgetRef ref,
  ) {
    final statusAsync = ref.watch(
      friendshipStatusProvider(
        FriendshipArgs(
          currentUserId: currentUserId,
          targetUserId: targetUserId,
        ),
      ),
    );

    return Center(
      child: statusAsync.when(
        data: (status) {
          String label;
          IconData icon;
          VoidCallback? onPressed;
          bool isOutlined = false;

          final firestoreService = ref.read(firestoreServiceProvider);

          switch (status) {
            case FriendshipStatus.notFriends:
              label = 'Arkadaş Ekle';
              icon = Icons.person_add;
              onPressed = () async {
                try {
                  await firestoreService.sendFriendRequest(
                    currentUserId,
                    targetUserId,
                  );
                  if (context.mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Arkadaşlık isteği gönderildi.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      // ignore: use_build_context_synchronously
                      context,
                    ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                  }
                }
              };
              break;
            case FriendshipStatus.requestSent:
              label = 'İstek Gönderildi';
              icon = Icons.how_to_reg;
              isOutlined = true;
              onPressed = () async {
                try {
                  await firestoreService.cancelFriendRequest(
                    currentUserId,
                    targetUserId,
                  );
                  if (context.mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('İstek iptal edildi.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      // ignore: use_build_context_synchronously
                      context,
                    ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                  }
                }
              };
              break;
            case FriendshipStatus.requestReceived:
              label = 'İsteği Yanıtla';
              icon = Icons.playlist_add_check;
              onPressed = () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yakında eklenecek')),
                );
              };
              break;
            case FriendshipStatus.friends:
              label = 'Arkadaşlardan Çıkar';
              icon = Icons.person_remove;
              isOutlined = true;
              onPressed = () async {
                try {
                  await firestoreService.removeFriend(
                    currentUserId,
                    targetUserId,
                  );
                  if (context.mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Arkadaşlıktan çıkarıldı.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      // ignore: use_build_context_synchronously
                      context,
                    ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                  }
                }
              };
              break;
          }

          if (isOutlined) {
            return OutlinedButton.icon(
              icon: Icon(icon),
              label: Text(label, textAlign: TextAlign.center),
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }

          return ElevatedButton.icon(
            icon: Icon(icon),
            label: Text(label, textAlign: TextAlign.center),
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? AppTheme.primary : AppTheme.textHint,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
        ),
      ],
    );
  }
}
