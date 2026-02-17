import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../viewmodels/navigation_provider.dart';
import '../viewmodels/providers.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';

class MainWrapper extends ConsumerWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final authState = ref.watch(authStateProvider);

    // Screens
    final screens = [
      const HomeScreen(),
      const _DiscussionsPlaceholder(),
      authState.value?.uid != null
          ? ProfileScreen(userId: authState.value!.uid)
          : const _ProfilePlaceholder(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.home,
                  label: 'Ana Sayfa',
                  isActive: currentIndex == 0,
                  onTap: () {
                    ref.read(bottomNavIndexProvider.notifier).state = 0;
                  },
                ),
                _NavBarItem(
                  icon: Icons.forum,
                  label: 'Tartışmalar',
                  isActive: currentIndex == 1,
                  onTap: () {
                    ref.read(bottomNavIndexProvider.notifier).state = 1;
                  },
                ),
                _NavBarItem(
                  icon: Icons.person,
                  label: 'Profil',
                  isActive: currentIndex == 2,
                  onTap: () {
                    ref.read(bottomNavIndexProvider.notifier).state = 2;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.textHint,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.textHint,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscussionsPlaceholder extends StatelessWidget {
  const _DiscussionsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum, size: 80, color: AppTheme.primary),
            SizedBox(height: 16),
            Text(
              'Tartışmalar',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Yakında...', style: TextStyle(color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80, color: AppTheme.textHint),
            SizedBox(height: 16),
            Text(
              'Lütfen giriş yapın',
              style: TextStyle(color: AppTheme.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
