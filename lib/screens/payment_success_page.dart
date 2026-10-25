import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../models/transaction.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/receipt_card.dart';

class PaymentSuccessPage extends StatelessWidget {
  final TrxItem trx;
  const PaymentSuccessPage({super.key, required this.trx});

  @override
  Widget build(BuildContext context) {
    final isCash = trx.cashReceived != null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                children: [
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutBack,
                      builder: (_, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.ok,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ok.withAlpha(90),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 54),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Pembayaran Berhasil',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(formatRupiah(trx.amount),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 28)),
                  if (isCash) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.okBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Kembalian ${formatRupiah(trx.change)}',
                            style: const TextStyle(
                                color: AppColors.ok,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  ReceiptCard(trx: trx),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                children: [
                  GradientButton(
                    label: 'Transaksi Baru',
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.orange),
                    child: const Text('Selesai, kembali ke beranda',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
