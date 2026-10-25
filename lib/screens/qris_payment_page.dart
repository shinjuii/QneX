import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../services/payment_gateway.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/qr_painter.dart';

/// Hasil: true = dibayar, false = QR kedaluwarsa, null = dibatalkan kasir.
class QrisPaymentPage extends StatefulWidget {
  final String orderId;
  final int amount;
  const QrisPaymentPage({super.key, required this.orderId, required this.amount});

  @override
  State<QrisPaymentPage> createState() => _QrisPaymentPageState();
}

class _QrisPaymentPageState extends State<QrisPaymentPage> {
  QrisCharge? _charge;
  Timer? _timer;
  Duration _left = Duration.zero;
  bool _expired = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    final c = _charge;
    if (c != null) paymentGateway.cancel(c);
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _charge = null;
    });
    try {
      final c = await paymentGateway.createQrisCharge(
          orderId: widget.orderId, amount: widget.amount);
      if (!mounted) {
        paymentGateway.cancel(c);
        return;
      }
      setState(() {
        _charge = c;
        _left = c.expiresAt.difference(DateTime.now());
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

      final paid = await paymentGateway.waitUntilPaid(c);
      if (mounted && paid) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Gagal membuat QR. Periksa koneksi lalu coba lagi.');
      }
    }
  }

  void _tick() {
    final c = _charge;
    if (c == null || !mounted) return;
    final left = c.expiresAt.difference(DateTime.now());
    if (left <= Duration.zero) {
      _timer?.cancel();
      paymentGateway.cancel(c);
      setState(() {
        _left = Duration.zero;
        _expired = true;
      });
    } else {
      setState(() => _left = left);
    }
  }

  String get _countdown {
    final m = _left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final gw = paymentGateway;
    final charge = _charge;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: AppColors.cream,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.ink),
          onPressed: () => Navigator.pop(context, _expired ? false : null),
        ),
        title: const Text('Pembayaran QRIS',
            style: TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 44, color: AppColors.muted),
                    const SizedBox(height: 10),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orange),
                      onPressed: _start,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : charge == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.orange),
                      SizedBox(height: 14),
                      Text('Membuat kode QR...',
                          style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  children: [
                    const Text('Total pembayaran',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    const SizedBox(height: 2),
                    Text(formatRupiah(widget.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 30)),
                    const SizedBox(height: 18),

                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.line),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(painter: QrPainter()),
                            ),
                            if (_expired)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(235),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Text('QR kedaluwarsa',
                                    style: TextStyle(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: _expired
                          ? const Text('Waktu pembayaran habis',
                              style: TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.orange),
                                ),
                                const SizedBox(width: 10),
                                const Text('Menunggu pembayaran',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(_countdown,
                                      style: const TextStyle(
                                          color: AppColors.orange,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5)),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text('Order #${widget.orderId}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11.5)),
                    const SizedBox(height: 14),
                    const Text(
                      'Minta pelanggan membuka e-wallet atau m-banking, '
                      'pilih Scan QRIS, lalu arahkan ke kode di atas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.45),
                    ),
                    const SizedBox(height: 22),

                    // Hanya muncul selama masih memakai gateway simulasi.
                    if (gw is MockPaymentGateway && !_expired)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.amberBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'MODE SIMULASI: belum terhubung ke Midtrans, '
                              'QR di atas hanya contoh.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.amber,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => gw.simulatePaid(charge),
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 18),
                              label: const Text('Simulasikan pembayaran berhasil'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.amber,
                                side: const BorderSide(color: AppColors.amber),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    if (_expired)
                      GradientButton(
                        label: 'Tutup',
                        onPressed: () => Navigator.pop(context, false),
                      )
                    else
                      TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger),
                        child: const Text('Batalkan pembayaran'),
                      ),
                  ],
                ),
    );
  }
}
