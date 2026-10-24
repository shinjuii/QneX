import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/product.dart';

/// Foto produk. Kalau belum ada foto, tampil ikon sesuai kategori.
class ProductThumb extends StatelessWidget {
  final Product product;
  final double size;
  final double radius;

  const ProductThumb({
    super.key,
    required this.product,
    this.size = 52,
    this.radius = 14,
  });

  Widget _fallback() => Container(
        width: size,
        height: size,
        color: AppColors.card,
        child: Icon(product.icon, color: AppColors.orange, size: size * 0.5),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: product.photo != null
          ? Image.memory(
              product.photo!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }
}
