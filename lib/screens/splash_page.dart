import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/float_tile.dart';
import 'login_page.dart';

class _SplashColors {
  static const top = Color(0xFFFFF6D6);
  static const bottom = Color(0xFFFAB93D);
  static const brown = Color(0xFF5A3A1A);
  static const tagline = Color(0xFF7A5A3A);
  static const shopWindow = Color(0xFFFFE9A8);
  static const roof = Color(0xFFE8571E);
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // Lama splash screen. Ubah angka ini kalau mau lebih cepat/lambat.
  static const _duration = Duration(milliseconds: 2800);

  late final AnimationController _c;
  late final Animation<double> _logo;
  late final Animation<double> _illus;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _duration);
    _logo = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _illus = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.15, 0.5, curve: Curves.easeOut),
    );
    _progress = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.1, 1.0, curve: Curves.easeInOut),
    );

    _c.forward().whenComplete(_goNext);
  }

  void _goNext() {
    if (!mounted) return;
    // Setelah splash, masuk ke halaman Login.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_SplashColors.top, _SplashColors.bottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _logo,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(_logo),
                  child: const _SplashLogo(),
                ),
              ),
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _illus,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(_illus),
                  child: const _SplashIllustration(),
                ),
              ),
              const SizedBox(height: 22),
              _LoadingBar(progress: _progress),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 4),
              child: Text(
                'QNEX',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: _SplashColors.brown,
                ),
              ),
            ),
            Positioned(
              right: -12,
              top: -2,
              child: Icon(Icons.north_east, color: AppColors.orange, size: 24),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          'Kelola Usaha, Lebih Mudah\nuntuk UMKM',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: _SplashColors.tagline,
          ),
        ),
      ],
    );
  }
}

class _LoadingBar extends StatelessWidget {
  final Animation<double> progress;
  const _LoadingBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, __) => SizedBox(
        width: 140,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.value,
            minHeight: 6,
            backgroundColor: Colors.white.withAlpha(110),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
          ),
        ),
      ),
    );
  }
}

/// Ilustrasi toko dibuat dari widget Flutter supaya langsung jalan.
/// Kalau nanti mau pakai gambar asli dari Figma, ganti isi widget ini
/// dengan Image.asset('assets/splash_illustration.png').
class _SplashIllustration extends StatelessWidget {
  const _SplashIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 260,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(90),
            ),
          ),
          const _Shop(),
          const Positioned(
            left: 22,
            top: 70,
            child: FloatTile(Icons.bar_chart_rounded),
          ),
          const Positioned(
            right: 26,
            top: 24,
            child: FloatTile(Icons.view_in_ar_outlined),
          ),
          const Positioned(
            left: 26,
            bottom: 24,
            child: FloatTile(Icons.credit_card_outlined),
          ),
          const Positioned(
            right: 24,
            bottom: 80,
            child: Icon(
              Icons.near_me_outlined,
              size: 34,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _Shop extends StatelessWidget {
  const _Shop();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 170,
      child: Stack(
        children: [
          // dinding toko
          Positioned(
            left: 12,
            right: 12,
            top: 58,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
            ),
          ),
          // jendela
          Positioned(
            left: 28,
            top: 98,
            child: Container(
              width: 70,
              height: 48,
              decoration: BoxDecoration(
                color: _SplashColors.shopWindow,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          // pintu
          Positioned(
            right: 28,
            top: 92,
            bottom: 0,
            child: Container(
              width: 50,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 7),
              decoration: const BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              ),
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // kanopi bergaris oranye-putih
          Positioned(
            left: 0,
            right: 0,
            top: 16,
            child: Row(
              children: List.generate(
                6,
                (i) => Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: i.isEven ? AppColors.orange : Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // atap
          Positioned(
            left: 6,
            right: 6,
            top: 0,
            child: Container(
              height: 20,
              decoration: const BoxDecoration(
                color: _SplashColors.roof,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
