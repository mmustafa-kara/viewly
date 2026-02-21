import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../viewmodels/user_viewmodel.dart';
import 'profile_screen.dart';

class FriendsScreen extends ConsumerWidget {
  final String userId;

  const FriendsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Arkadaşlar')),
      body: friendsAsync.when(
        data: (friends) {
          if (friends.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppTheme.textHint,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Henüz arkadaş bulunmuyor.',
                    style: TextStyle(color: AppTheme.textHint),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  backgroundImage: friend.photoUrl != null
                      ? NetworkImage(friend.photoUrl!)
                      : null,
                  child: friend.photoUrl == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                title: Text('@${friend.displayUsername}'),
                subtitle: friend.displayName != null
                    ? Text(
                        friend.displayName!,
                        style: const TextStyle(color: AppTheme.textHint),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(visitedUserId: friend.uid),
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
}
