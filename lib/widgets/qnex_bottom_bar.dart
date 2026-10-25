import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../screens/kasir_page.dart';

/// Cara pakai di Scaffold mana pun:
///
/// Scaffold(
///   floatingActionButtonLocation: QnexCartFab.location,
///   floatingActionButton: const QnexCartFab(),  // otomatis membuka Kasir
///   bottomNavigationBar: QnexBottomBar(currentIndex: 0, onTap: (i) {}),
///   ...
/// )
///
/// Index tab: 0 Home, 1 Wishlist, 3 Search, 4 Setting (2 = tombol keranjang).
class QnexBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const QnexBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.barBg,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              active: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.favorite_border,
              label: 'Wishlist',
              active: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            const Expanded(child: SizedBox()), // ruang untuk tombol keranjang
            _NavItem(
              icon: Icons.search,
              label: 'Search',
              active: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              label: 'Setting',
              active: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol keranjang bulat di tengah bottom bar.
/// Kalau onPressed tidak diisi, otomatis membuka halaman Kasir/POS.
class QnexCartFab extends StatelessWidget {
  final VoidCallback? onPressed;
  const QnexCartFab({super.key, this.onPressed});

  static const location = FloatingActionButtonLocation.centerDocked;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed ??
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KasirPage()),
              ),
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: const Icon(Icons.shopping_cart_outlined),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.orange : AppColors.ink;

    return Expanded(
      // InkResponse = efek ripple (gelombang) bulat saat ditekan
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        containedInkWell: false,
        highlightShape: BoxShape.circle,
        splashFactory: InkRipple.splashFactory,
        splashColor: AppColors.orange.withAlpha(75),
        highlightColor: AppColors.orange.withAlpha(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
