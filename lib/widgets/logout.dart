import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../data/session_store.dart';
import '../screens/login_page.dart';

/// Menampilkan konfirmasi, lalu keluar dan kembali ke halaman Login.
/// Semua halaman sebelumnya dibuang, jadi tombol Kembali tidak bisa
/// membawa pengguna masuk lagi tanpa login.
Future<void> confirmAndLogout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.logout, color: AppColors.danger, size: 32),
      title: const Text('Keluar dari akun?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: const Text(
        'Kamu perlu masuk lagi untuk memakai QNEX.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  SessionStore.instance.signOut();
  Navigator.of(context).pushAndRemoveUntil(
    fadeRoute(const LoginPage()),
    (route) => false,
  );
}
