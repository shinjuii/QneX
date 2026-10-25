import 'package:flutter/material.dart';
import '../models/transaction.dart';

/// Daftar transaksi yang dipakai bersama (kasir menambah, riwayat membaca).
/// Nanti diganti dengan data dari database.
class TransactionStore extends ChangeNotifier {
  TransactionStore._() {
    _items.addAll([
      TrxItem('TRX250412001', 45000, 'QRIS', DateTime(2025, 4, 12, 14, 32), TrxStatus.berhasil),
      TrxItem('TRX250412000', 25000, 'Tunai', DateTime(2025, 4, 12, 13, 17), TrxStatus.berhasil),
      TrxItem('TRX250411099', 16000, 'QRIS', DateTime(2025, 4, 11, 17, 45), TrxStatus.berhasil),
      TrxItem('TRX250411098', 32000, 'Tunai', DateTime(2025, 4, 11, 16, 20), TrxStatus.berhasil),
      TrxItem('TRX250411097', 18000, 'QRIS', DateTime(2025, 4, 11, 15, 52), TrxStatus.gagal),
    ]);
  }
  static final TransactionStore instance = TransactionStore._();

  final List<TrxItem> _items = [];
  List<TrxItem> get items => List.unmodifiable(_items);

  /// Nomor transaksi: TRX + yyMMdd + urutan hari itu, contoh TRX261024003.
  String nextId() {
    final n = DateTime.now();
    final prefix = 'TRX${(n.year % 100).toString().padLeft(2, '0')}'
        '${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}';
    final count = _items.where((t) => t.id.startsWith(prefix)).length + 1;
    return '$prefix${count.toString().padLeft(3, '0')}';
  }

  void add(TrxItem t) {
    _items.insert(0, t);
    notifyListeners();
  }
}
