import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/product.dart';
import 'cart_controller.dart';

/// Penyimpanan produk sementara (di memori) yang dipakai bersama semua halaman.
/// Nanti isinya diganti dengan data dari database, bentuk pemakaiannya sama.
class ProductStore extends ChangeNotifier {
  ProductStore._() {
    _seed();
  }
  static final ProductStore instance = ProductStore._();

  final List<Product> _items = [];
  List<Product> get products => List.unmodifiable(_items);

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void add(Product p) {
    _items.insert(0, p);
    notifyListeners();
  }

  /// Panggil setelah mengubah field produk secara langsung.
  void update() => notifyListeners();

  void remove(Product p) {
    _items.remove(p);
    notifyListeners();
  }

  void restock(Product p, int qty, {String note = 'Stok masuk'}) {
    p.stock += qty;
    p.history.insert(0, StockLog(DateTime.now(), qty, note));
    notifyListeners();
  }

  /// Mengurangi stok sesuai isi keranjang saat penjualan berhasil.
  void sell(List<CartLine> lines, String trxId) {
    final now = DateTime.now();
    for (final l in lines) {
      l.product.stock = (l.product.stock - l.qty).clamp(0, 1 << 30).toInt();
      l.product.history.insert(0, StockLog(now, -l.qty, 'Penjualan $trxId'));
    }
    notifyListeners();
  }

  void setPhoto(Product p, Uint8List? bytes) {
    p.photo = bytes;
    notifyListeners();
  }

  void _seed() {
    final today = dateOnly(DateTime.now());
    DateTime d(int n) => DateTime(today.year, today.month, today.day + n);

    Product mk(String id, String name, String cat, String unit, int price,
        int cost, int stock, int min, int cap, DateTime entry, DateTime? exp,
        String loc, IconData icon) {
      return Product(
        id: id,
        name: name,
        category: cat,
        unit: unit,
        price: price,
        costPrice: cost,
        stock: stock,
        minStock: min,
        capacity: cap,
        entryDate: entry,
        expiry: exp,
        location: loc,
        icon: icon,
        history: [StockLog(entry, stock, 'Stok awal')],
      );
    }

    _items.addAll([
      mk('p10', 'Es Teh Manis', 'Minuman', 'Pcs', 5000, 2500, 28, 10, 60,
          d(-1), null, 'Kasir', Icons.local_cafe),
      mk('p1', 'Indomie Goreng', 'Makanan', 'Bungkus', 3000, 2000, 19, 10, 100,
          DateTime(2026, 10, 9), null, 'Rak A1', Icons.ramen_dining),
      mk('p2', 'Susu UHT Cokelat 200ml', 'Minuman', 'Pcs', 6500, 5200, 32, 12,
          60, d(-10), d(9), 'Kulkas 1', Icons.local_drink),
      mk('p3', 'Teh Botol 450ml', 'Minuman', 'Botol', 5000, 3800, 4, 12, 48,
          d(-14), d(200), 'Rak B2', Icons.emoji_food_beverage),
      mk('p4', 'Gula Pasir 1kg', 'Sembako', 'Kg', 17000, 15000, 6, 10, 40,
          d(-20), null, 'Rak C1', Icons.grain),
      mk('p5', 'Minyak Goreng 1L', 'Sembako', 'Liter', 18500, 16500, 22, 10,
          40, d(-12), d(300), 'Rak C2', Icons.opacity),
      mk('p6', 'Kopi Susu Botol', 'Minuman', 'Botol', 12000, 9000, 3, 10, 30,
          d(-6), d(20), 'Kulkas 1', Icons.coffee),
      mk('p7', 'Roti Coklat', 'Makanan', 'Pcs', 8000, 6000, 5, 10, 40, d(-4),
          d(2), 'Rak A2', Icons.bakery_dining),
      mk('p8', 'Air Mineral 600ml', 'Minuman', 'Botol', 4000, 2800, 8, 15, 60,
          d(-18), d(400), 'Rak B1', Icons.water_drop),
      mk('p9', 'Biskuit Kelapa', 'Makanan', 'Bungkus', 9000, 7000, 30, 10, 50,
          d(-60), d(-3), 'Rak A3', Icons.cookie),
    ]);
  }
}
