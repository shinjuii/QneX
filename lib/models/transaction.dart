enum TrxStatus { berhasil, gagal }

/// Satu baris barang di struk.
class TrxLine {
  final String name;
  final int qty;
  final int price;
  const TrxLine(this.name, this.qty, this.price);

  int get subtotal => qty * price;
}

class TrxItem {
  final String id;
  final int amount;
  final String method;
  final DateTime time;
  final TrxStatus status;
  final List<TrxLine> lines;
  final int? cashReceived; // hanya untuk pembayaran tunai

  TrxItem(
    this.id,
    this.amount,
    this.method,
    this.time,
    this.status, {
    this.lines = const [],
    this.cashReceived,
  });

  int get change => cashReceived == null ? 0 : cashReceived! - amount;
}
