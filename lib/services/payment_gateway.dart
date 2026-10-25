import 'dart:async';

/// Tagihan QRIS yang dibuat untuk satu pesanan.
class QrisCharge {
  final String orderId;
  final int amount;
  final DateTime expiresAt;
  final String qrData; // isi QR (dari Midtrans nanti berupa string QRIS / URL gambar)

  const QrisCharge({
    required this.orderId,
    required this.amount,
    required this.expiresAt,
    required this.qrData,
  });
}

/// Pintu masuk ke penyedia pembayaran.
///
/// Untuk Midtrans: buat class `MidtransPaymentGateway implements PaymentGateway`.
///  - createQrisCharge -> panggil backend-mu (yang memegang Server Key Midtrans)
///    untuk membuat transaksi QRIS, lalu kembalikan data QR-nya.
///  - waitUntilPaid -> cek status ke backend secara berkala (atau lewat
///    notifikasi/webhook Midtrans yang diteruskan backend).
/// Server Key Midtrans TIDAK boleh ditaruh di aplikasi Flutter.
/// Setelah itu cukup ganti baris `paymentGateway` di bawah.
abstract class PaymentGateway {
  Future<QrisCharge> createQrisCharge({
    required String orderId,
    required int amount,
  });

  /// true = sudah dibayar, false = dibatalkan / kedaluwarsa.
  Future<bool> waitUntilPaid(QrisCharge charge);

  void cancel(QrisCharge charge);
}

/// Versi simulasi supaya alur kasir bisa dicoba tanpa Midtrans.
class MockPaymentGateway implements PaymentGateway {
  final Map<String, Completer<bool>> _pending = {};

  @override
  Future<QrisCharge> createQrisCharge({
    required String orderId,
    required int amount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    _pending[orderId] = Completer<bool>();
    return QrisCharge(
      orderId: orderId,
      amount: amount,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      qrData: 'SIMULASI-QRIS-$orderId',
    );
  }

  @override
  Future<bool> waitUntilPaid(QrisCharge charge) {
    final c = _pending[charge.orderId];
    return c == null ? Future.value(false) : c.future;
  }

  @override
  void cancel(QrisCharge charge) {
    _pending.remove(charge.orderId)?.complete(false);
  }

  /// Hanya ada di simulasi: pura-pura pelanggan sudah membayar.
  void simulatePaid(QrisCharge charge) {
    _pending.remove(charge.orderId)?.complete(true);
  }
}

/// Gateway yang dipakai aplikasi. Ganti ke Midtrans kalau backend sudah siap.
PaymentGateway paymentGateway = MockPaymentGateway();
