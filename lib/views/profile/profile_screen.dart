import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/providers.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider(userId));
    final userPosts = ref.watch(userPostsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
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
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppTheme.error),
                    SizedBox(width: 12),
                    Text('Çıkış Yap', style: TextStyle(color: AppTheme.error)),
                  ],
                ),
                onTap: () async {
                  final authService = ref.read(authServiceProvider);
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
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
                  user.displayName ?? '@${user.email.split('@')[0]}',
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

                // Edit Profile Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Profili Düzenle'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tabs
                DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        indicatorColor: AppTheme.primary,
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: AppTheme.textHint,
                        tabs: [
                          Tab(text: 'Geçmiş\nTartışmalarım'),
                          Tab(text: 'Kaydedilenler'),
                          Tab(text: 'Beğenilenler'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Posts List
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
                      ),
                    ],
                  ),
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
