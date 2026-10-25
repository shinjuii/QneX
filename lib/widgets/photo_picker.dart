import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';

/// Membuka pilihan Galeri / Kamera lalu mengembalikan foto yang dipilih
/// (dalam bentuk bytes), atau null kalau dibatalkan.
Future<Uint8List?> pickProductPhoto(BuildContext context,
    {String title = 'Foto Produk'}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E4E4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.orange),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.orange),
                title: const Text('Ambil dengan kamera'),
                onTap: () => Navigator.pop(sheet, ImageSource.camera),
              ),
          ],
        ),
      ),
    ),
  );
  if (source == null) return null;

  try {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return null;
    return await file.readAsBytes();
  } catch (_) {
    if (context.mounted) {
      showSnack(context, 'Foto tidak bisa dibuka. Coba lagi.');
    }
    return null;
  }
}
