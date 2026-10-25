import 'package:flutter/material.dart';
import '../models/product.dart';

class CartLine {
  final Product product;
  int qty;
  CartLine(this.product, this.qty);

  int get subtotal => product.price * qty;
}

/// Keranjang kasir untuk satu transaksi.
class CartController extends ChangeNotifier {
  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();
  bool get isEmpty => _lines.isEmpty;
  int get itemCount => _lines.values.fold(0, (a, l) => a + l.qty);
  int get total => _lines.values.fold(0, (a, l) => a + l.subtotal);

  int qtyOf(Product p) => _lines[p.id]?.qty ?? 0;

  /// Mengembalikan false kalau jumlahnya sudah mentok di stok.
  bool add(Product p) {
    if (qtyOf(p) >= p.stock) return false;
    final line = _lines[p.id];
    if (line == null) {
      _lines[p.id] = CartLine(p, 1);
    } else {
      line.qty += 1;
    }
    notifyListeners();
    return true;
  }

  void decrement(Product p) {
    final line = _lines[p.id];
    if (line == null) return;
    if (line.qty <= 1) {
      _lines.remove(p.id);
    } else {
      line.qty -= 1;
    }
    notifyListeners();
  }

  void remove(Product p) {
    _lines.remove(p.id);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
