import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

const kCategories = ['Makanan', 'Minuman', 'Sembako', 'Kebersihan', 'Lainnya'];
const kUnits = ['Pcs', 'Bungkus', 'Botol', 'Kg', 'Liter', 'Dus'];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

IconData iconForCategory(String category) {
  switch (category) {
    case 'Makanan':
      return Icons.ramen_dining;
    case 'Minuman':
      return Icons.local_drink;
    case 'Sembako':
      return Icons.grain;
    case 'Kebersihan':
      return Icons.cleaning_services;
    default:
      return Icons.inventory_2_outlined;
  }
}

/// Satu catatan pergerakan stok (positif = masuk, negatif = keluar).
class StockLog {
  final DateTime date;
  final int qty;
  final String note;
  const StockLog(this.date, this.qty, this.note);
}

class Product {
  final String id;
  String name;
  String category;
  String unit;
  int price; // harga jual
  int costPrice; // harga modal
  int stock;
  int minStock; // di bawah/sama dengan ini = "Minim"
  int capacity; // stok penuh, untuk panjang bar
  DateTime entryDate;
  DateTime? expiry;
  String location;
  Uint8List? photo; // foto yang diunggah owner
  IconData icon; // dipakai kalau belum ada foto
  final List<StockLog> history;

  Product({
    required this.id,
    required this.name,
    required this.category,
    this.unit = 'Pcs',
    required this.price,
    this.costPrice = 0,
    required this.stock,
    required this.minStock,
    required this.capacity,
    required this.entryDate,
    this.expiry,
    this.location = '',
    this.photo,
    this.icon = Icons.inventory_2_outlined,
    List<StockLog>? history,
  }) : history = history ?? <StockLog>[];

  bool get isLow => stock <= minStock;

  int? daysToExpiry(DateTime today) =>
      expiry == null ? null : dateOnly(expiry!).difference(today).inDays;
}

/// ---------- Status produk (dipakai daftar inventori & halaman detail) ----------
class ProductStatus {
  final String label;
  final Color fg;
  final Color bg;
  const ProductStatus(this.label, this.fg, this.bg);
}

ProductStatus statusOf(Product p, DateTime today) {
  final d = p.daysToExpiry(today);
  if (d != null && d < 0) {
    return const ProductStatus('Kedaluwarsa', AppColors.danger, AppColors.dangerBg);
  }
  if (p.isLow) {
    return const ProductStatus('Minim', AppColors.orange, AppColors.warnBg);
  }
  if (d != null && d <= 14) {
    return const ProductStatus('Hampir exp', AppColors.amber, AppColors.amberBg);
  }
  return const ProductStatus('Normal', AppColors.ok, AppColors.okBg);
}
