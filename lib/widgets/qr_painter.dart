import 'dart:math';
import 'package:flutter/material.dart';

/// Pola QR contoh (bukan QR asli). Dipakai di ilustrasi login dan
/// halaman QRIS mode simulasi.
class QrPainter extends CustomPainter {
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
          Rect.fromLTWH(c0 * cell, r0 * cell, 5 * cell, 5 * cell), dark);
      canvas.drawRect(
          Rect.fromLTWH((c0 + 1) * cell, (r0 + 1) * cell, 3 * cell, 3 * cell),
          light);
      canvas.drawRect(
          Rect.fromLTWH((c0 + 2) * cell, (r0 + 2) * cell, cell, cell), dark);
    }

    finder(0, 0);
    finder(0, n - 5);
    finder(n - 5, 0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
