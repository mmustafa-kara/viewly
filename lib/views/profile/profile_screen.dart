import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/models/movie_model.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/providers.dart';
import '../../widgets/movie_card.dart';
import '../detail/movie_detail_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider(widget.userId));
    final userPosts = ref.watch(userPostsProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Çıkış Yap',
          onPressed: () async {
            final authService = ref.read(authServiceProvider);
            await authService.signOut();
            // Auth state change will automatically trigger AuthGate to show LoginScreen
          },
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Profili Düzenle'),
                  ],
                ),
                onTap: () {},
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Ayarlar'),
                  ],
                ),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
      body: userProfile.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'Kullanıcı bulunamadı',
                style: TextStyle(color: AppTheme.textHint),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
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
                      _StatItem(
                        label: 'TAKİPÇİ',
                        value: _formatNumber(user.followersCount),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppTheme.textHint.withOpacity(0.2),
                      ),
                      _StatItem(
                        label: 'TAKİP',
                        value: _formatNumber(user.followingCount),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppTheme.textHint.withOpacity(0.2),
                      ),
                      _StatItem(
                        label: 'TARTIŞMA',
                        value: _formatNumber(user.postsCount),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Share Profile Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Profili Paylaş'),
                    ),
                  ),
                ),
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
                            label: 'Geçmiş\nTartışmalarım',
                            isActive: _selectedTabIndex == 0,
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 0;
                              });
                            },
                          ),
                          _TabButton(
                            label: 'Kaydedilenler',
                            isActive: _selectedTabIndex == 1,
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 1;
                              });
                            },
                          ),
                          _TabButton(
                            label: 'Beğenilenler',
                            isActive: _selectedTabIndex == 2,
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 2;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab Content
                    if (_selectedTabIndex == 0)
                      // Tab 1: User Posts
                      userPosts.when(
                        data: (snapshot) {
                          final posts = snapshot.docs;
                          if (posts.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: AppTheme.textHint,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Henüz tartışma yok',
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
                              final post =
                                  posts[index].data() as Map<String, dynamic>;
                              final timestamp = post['createdAt'];
                              final date = timestamp != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(timestamp.toDate())
                                  : '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.movie,
                                          size: 16,
                                          color: AppTheme.secondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            post['movieTitle'] ?? 'Film',
                                            style: const TextStyle(
                                              color: AppTheme.secondary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            color: AppTheme.textHint,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      post['content'] ?? '',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.favorite_border,
                                          size: 16,
                                          color: AppTheme.textHint,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${post['likes'] ?? 0}',
                                          style: const TextStyle(
                                            color: AppTheme.textHint,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(
                                          Icons.comment,
                                          size: 16,
                                          color: AppTheme.textHint,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${post['comments'] ?? 0}',
                                          style: const TextStyle(
                                            color: AppTheme.textHint,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
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
                      )
                    else if (_selectedTabIndex == 1)
                      // Tab 2: Saved Movies
                      Consumer(
                        builder: (context, ref, _) {
                          final firestoreService = ref.watch(
                            firestoreServiceProvider,
                          );
                          final favoritesStream = firestoreService
                              .getFavoriteMovies(widget.userId);

                          return StreamBuilder<List<MovieModel>>(
                            stream: favoritesStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                );
                              }

                              final movies = snapshot.data ?? [];

                              if (movies.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.bookmark_border,
                                        size: 64,
                                        color: AppTheme.textHint,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Henüz kaydedilen film yok',
                                        style: TextStyle(
                                          color: AppTheme.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.65,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount: movies.length,
                                itemBuilder: (context, index) {
                                  return MovieCard(
                                    movie: movies[index],
                                    width: double.infinity,
                                    height: double.infinity,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MovieDetailScreen(
                                            movie: movies[index],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      )
                    else
                      // Tab 3: Liked Posts (Placeholder)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 64,
                              color: AppTheme.textHint,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Henüz beğenilmedi',
                              style: TextStyle(color: AppTheme.textHint),
                            ),
                          ],
                        ),
                      ),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : AppTheme.textHint,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
