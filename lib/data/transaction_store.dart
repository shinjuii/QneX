import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';

class TransactionStore extends ChangeNotifier {
  TransactionStore._() {
    loadTransactions();
  }
  static final TransactionStore instance = TransactionStore._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final List<TrxItem> _items = [];

  List<TrxItem> get items => List.unmodifiable(_items);

  String nextId() => 'TRX-${DateTime.now().millisecondsSinceEpoch}';

  /// Memuat riwayat transaksi beserta itemnya dari Supabase
  Future<void> loadTransactions() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('*, transaction_items(*)')
          .order('created_at', ascending: false);

      _items.clear();
      for (var row in response) {
        final List rawLines = row['transaction_items'] ?? [];
        final trxLines = rawLines.map((li) {
          return TrxLine(
            li['product_name'] ?? 'Produk',
            li['quantity'] ?? li['qty'] ?? 1, // Menyesuaikan kolom quantity/qty di database
            (li['price_at_sale'] ?? li['price'] as num?)?.toInt() ?? 0,
          );
        }).toList();

        _items.add(TrxItem(
          row['id']?.toString() ?? '',
          (row['total_amount'] as num?)?.toInt() ?? 0,
          row['payment_method'] ?? 'Tunai',
          row['created_at'] != null ? DateTime.parse(row['created_at']) : DateTime.now(),
          row['status'] == 'Gagal' ? TrxStatus.gagal : TrxStatus.berhasil,
          lines: trxLines,
        ));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat transaksi dari Supabase: $e');
    }
  }

  /// Menambah transaksi baru ke dalam list lokal dan memperbarui UI
  Future<void> add(TrxItem item) async {
    _items.insert(0, item);
    notifyListeners();
    // Data ke database Supabase sudah dikirimkan melalui ProductStore.sell(),
    // jadi kita cukup muat ulang agar sinkron dengan ID UUID dari database.
    await loadTransactions();
  }
}