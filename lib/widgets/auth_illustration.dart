import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'float_tile.dart';
import 'qr_painter.dart';

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
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
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
              child: CustomPaint(painter: QrPainter()),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('SCAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
