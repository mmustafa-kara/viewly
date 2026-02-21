import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../viewmodels/navigation_provider.dart';
import 'home/home_screen.dart';
import 'discussion/global_discussions_screen.dart';
import 'profile/profile_screen.dart';

class MainWrapper extends ConsumerWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    // MainWrapper is only reachable when authenticated, so currentUser is guaranteed non-null.

    // Define screens
    final List<Widget> screens = [
      const HomeScreen(),
      const GlobalDiscussionsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
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
