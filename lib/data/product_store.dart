import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import 'cart_controller.dart';

class ProductStore extends ChangeNotifier {
  ProductStore._() {
    loadProducts();
  }
  static final ProductStore instance = ProductStore._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final List<Product> _items = [];
  List<Product> get products => List.unmodifiable(_items);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Mengambil data produk dari tabel 'products' di Supabase
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.from('products').select('*');
      _items.clear();

      for (var row in response) {
        _items.add(Product(
          id: row['id']?.toString() ?? '',
          name: row['name'] ?? '',
          category: row['category'] ?? 'Umum',
          unit: row['unit'] ?? 'Pcs',
          price: (row['price'] as num?)?.toInt() ?? 0,
          costPrice: (row['cost_price'] as num?)?.toInt() ?? 0,
          stock: row['stock'] ?? 0,
          minStock: row['min_stock'] ?? 10,
          capacity: row['capacity'] ?? 50,
          entryDate: row['created_at'] != null ? DateTime.parse(row['created_at']) : DateTime.now(),
          expiry: row['expiry'] != null ? DateTime.parse(row['expiry']) : null,
          location: row['location'] ?? 'Utama',
          icon: Icons.inventory_2,
          history: [],
        ));
      }
    } catch (e) {
      debugPrint('Gagal memuat produk dari Supabase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menambah produk baru ke Supabase
  Future<void> add(Product p) async {
    try {
      await _supabase.from('products').insert({
        'name': p.name,
        'category': p.category,
        'unit': p.unit,
        'price': p.price,
        'cost_price': p.costPrice,
        'stock': p.stock,
        'min_stock': p.minStock,
        'capacity': p.capacity,
        'location': p.location,
        'barcode': 'BC-${DateTime.now().millisecondsSinceEpoch}',
        'expiry': p.expiry?.toIso8601String(),
      });
      await loadProducts();
    } catch (e) {
      debugPrint('Gagal menambah produk ke Supabase: $e');
    }
  }

  void update() => notifyListeners();

  /// Menghapus produk dari Supabase
  Future<void> remove(Product p) async {
    try {
      await _supabase.from('products').delete().eq('id', p.id);
      _items.remove(p);
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal menghapus produk dari Supabase: $e');
    }
  }

  /// Restock produk dan update ke Supabase
  Future<void> restock(Product p, int qty, {String note = 'Stok masuk'}) async {
    p.stock += qty;
    p.history.insert(0, StockLog(DateTime.now(), qty, note));
    try {
      await _supabase.from('products').update({'stock': p.stock}).eq('id', p.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal merestock produk di Supabase: $e');
    }
  }

  /// Proses penjualan: mengurangi stok di Supabase & mencatat transaksi
  Future<void> sell(List<CartLine> lines, String trxId) async {
    final now = DateTime.now();
    try {
      double totalAmount = lines.fold(0, (sum, l) => sum + (l.product.price * l.qty));

      // 1. Simpan ringkasan transaksi ke tabel 'transactions'
      // Menggunakan kolom sesuai skema Supabase: total_amount, payment_method, status
      final trxResponse = await _supabase.from('transactions').insert({
        'total_amount': totalAmount,
        'payment_method': 'Tunai',
        'status': 'Berhasil',
        'created_at': now.toIso8601String(),
      }).select('id').single();

      final String insertedTrxId = trxResponse['id'].toString();

      // 2. Update stok produk & simpan item transaksi
      for (final l in lines) {
        l.product.stock = (l.product.stock - l.qty).clamp(0, 1 << 30).toInt();
        l.product.history.insert(0, StockLog(now, -l.qty, 'Penjualan $trxId'));

        // Update stok di database produk
        await _supabase.from('products').update({'stock': l.product.stock}).eq('id', l.product.id);

        // Simpan detail item ke 'transaction_items' sesuai skema: quantity & price_at_sale
        await _supabase.from('transaction_items').insert({
          'transaction_id': insertedTrxId,
          'product_id': l.product.id,
          'quantity': l.qty,
          'price_at_sale': l.product.price,
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR SAAT MENJUAL PRODUK: $e');
    }
  }

  void setPhoto(Product p, Uint8List? bytes) {
    p.photo = bytes;
    notifyListeners();
  }
}