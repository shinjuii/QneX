import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'float_tile.dart';

/// Ilustrasi login: HP dengan QR + ikon melayang. Dibuat dari widget Flutter.
/// Kalau mau pakai ilustrasi asli dari Figma (orang + HP), ekspor PNG-nya lalu
/// ganti isi widget ini dengan Image.asset('assets/login_illustration.png').
class AuthIllustration extends StatefulWidget {
  const AuthIllustration();

  @override
  State<AuthIllustration> createState() => _AuthIllustrationState();
}

class _AuthIllustrationState extends State<AuthIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = Curves.easeInOut.transform(_c.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.yellow.withAlpha(70),
                ),
              ),
              Positioned(
                left: 34,
                bottom: 16,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange.withAlpha(50),
                  ),
                ),
              ),
              Positioned(
                right: 46,
                top: 10,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.yellow.withAlpha(120),
                  ),
                ),
              ),
              const _AuthPhone(),
              Positioned(
                left: 40,
                top: 34 + 6 * t,
                child: const FloatTile(Icons.check_circle_outline),
              ),
              Positioned(
                right: 40,
                bottom: 30 + 6 * (1 - t),
                child: const FloatTile(Icons.payments_outlined),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AuthPhone extends StatelessWidget {
  const _AuthPhone();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      height: 156,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B3A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(painter: _QrPainter()),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SCAN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const n = 13;
    final cell = size.width / n;
    final dark = Paint()..color = const Color(0xFF2B2B3A);
    final light = Paint()..color = Colors.white;
    final rnd = Random(7);

    bool inFinder(int r, int c) {
      bool zone(int r0, int c0) =>
          r >= r0 && r < r0 + 5 && c >= c0 && c < c0 + 5;
      return zone(0, 0) || zone(0, n - 5) || zone(n - 5, 0);
    }

    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (inFinder(r, c)) continue;
        if (rnd.nextDouble() > 0.5) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell + 0.5, r * cell + 0.5, cell - 1, cell - 1),
            dark,
          );
        }
      }
    }

    void finder(int r0, int c0) {
      canvas.drawRect(
        Rect.fromLTWH(c0 * cell, r0 * cell, 5 * cell, 5 * cell),
        dark,
      );
      canvas.drawRect(
        Rect.fromLTWH((c0 + 1) * cell, (r0 + 1) * cell, 3 * cell, 3 * cell),
        light,
      );
      canvas.drawRect(
        Rect.fromLTWH((c0 + 2) * cell, (r0 + 2) * cell, cell, cell),
        dark,
      );
    }

    finder(0, 0);
    finder(0, n - 5);
    finder(n - 5, 0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
