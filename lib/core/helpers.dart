import 'package:flutter/material.dart';
import 'app_colors.dart';

const authBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF1BF), Color(0xFFFFFBEF)],
  ),
);

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 450),
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) =>
      FadeTransition(opacity: anim, child: child),
);

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

String? validateIdentifier(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Email atau nomor HP wajib diisi';
  if (t.contains('@')) {
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
    return ok ? null : 'Format email tidak valid';
  }
  final digits = t.replaceAll(RegExp(r'[\s\-+]'), '');
  return RegExp(r'^\d{9,14}$').hasMatch(digits) ? null : 'Nomor HP tidak valid';
}

String? validatePassword(String? v) {
  if ((v ?? '').isEmpty) return 'Kata sandi wajib diisi';
  if (v!.length < 6) return 'Kata sandi minimal 6 karakter';
  return null;
}
