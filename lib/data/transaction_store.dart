import 'dart:math';
import 'package:flutter/material.dart';
import '../models/transaction.dart';

class _Sku {
  final String name;
  final int price;
  final int cost;
  final int weight; // makin besar makin sering terjual
  const _Sku(this.name, this.price, this.cost, this.weight);
}

const _catalog = [
  _Sku('Es Teh Manis', 5000, 2500, 5),
  _Sku('Indomie Goreng', 3000, 2000, 6),
  _Sku('Air Mineral 600ml', 4000, 2800, 5),
  _Sku('Roti Coklat', 8000, 6000, 3),
  _Sku('Kopi Susu Botol', 12000, 9000, 3),
  _Sku('Teh Botol 450ml', 5000, 3800, 3),
  _Sku('Susu UHT Cokelat 200ml', 6500, 5200, 2),
  _Sku('Biskuit Kelapa', 9000, 7000, 2),
  _Sku('Gula Pasir 1kg', 17000, 15000, 1),
  _Sku('Minyak Goreng 1L', 18500, 16500, 1),
];

class _Draft {
  final DateTime time;
  final List<TrxLine> lines;
  final String method;
  final bool failed;
  _Draft(this.time, this.lines, this.method, this.failed);
}

/// Daftar transaksi yang dipakai bersama (kasir menambah, riwayat dan laporan membaca).
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
    _seedRecent();
    _items.sort((a, b) => b.time.compareTo(a.time));
  }
  static final TransactionStore instance = TransactionStore._();

  final List<TrxItem> _items = [];
  List<TrxItem> get items => List.unmodifiable(_items);

  String _prefixFor(DateTime n) =>
      'TRX${(n.year % 100).toString().padLeft(2, '0')}'
      '${n.month.toString().padLeft(2, '0')}'
      '${n.day.toString().padLeft(2, '0')}';

  /// Nomor transaksi: TRX + yyMMdd + urutan hari itu, contoh TRX261024003.
  String nextId() {
    final prefix = _prefixFor(DateTime.now());
    final count = _items.where((t) => t.id.startsWith(prefix)).length + 1;
    return '$prefix${count.toString().padLeft(3, '0')}';
  }

  void add(TrxItem t) {
    _items.insert(0, t);
    notifyListeners();
  }

  /// Data contoh 3 minggu terakhir supaya Laporan Profit ada isinya.
  /// Dibuang saat database sungguhan dipakai.
  void _seedRecent() {
    final rnd = Random(42);
    final now = DateTime.now();
    final totalWeight = _catalog.fold<int>(0, (a, s) => a + s.weight);

    _Sku pick() {
      var r = rnd.nextInt(totalWeight);
      for (final s in _catalog) {
        if (r < s.weight) return s;
        r -= s.weight;
      }
      return _catalog.first;
    }

    for (var back = 1; back <= 21; back++) {
      final day = DateTime(now.year, now.month, now.day - back);
      final count = 3 + rnd.nextInt(4) + (day.weekday >= 6 ? 2 : 0);

      final drafts = <_Draft>[];
      for (var i = 0; i < count; i++) {
        final lines = <TrxLine>[];
        final used = <String>{};
        final lineCount = 1 + rnd.nextInt(3);
        for (var k = 0; k < lineCount; k++) {
          final s = pick();
          if (!used.add(s.name)) continue;
          lines.add(TrxLine(s.name, 1 + rnd.nextInt(3), s.price, cost: s.cost));
        }
        final method = rnd.nextBool() ? 'Tunai' : 'QRIS';
        final failed = method == 'QRIS' && rnd.nextInt(10) == 0;
        final time = DateTime(
            day.year, day.month, day.day, 8 + rnd.nextInt(12), rnd.nextInt(60));
        drafts.add(_Draft(time, lines, method, failed));
      }
      drafts.sort((a, b) => a.time.compareTo(b.time));

      final prefix = _prefixFor(day);
      for (var i = 0; i < drafts.length; i++) {
        final d = drafts[i];
        final amount = d.lines.fold<int>(0, (a, l) => a + l.subtotal);
        final cash = d.method == 'Tunai' && !d.failed
            ? ((amount + 4999) ~/ 5000) * 5000
            : null;
        _items.add(TrxItem(
          '$prefix${(i + 1).toString().padLeft(3, '0')}',
          amount,
          d.method,
          d.time,
          d.failed ? TrxStatus.gagal : TrxStatus.berhasil,
          lines: d.lines,
          cashReceived: cash,
        ));
      }
    }
  }
}
