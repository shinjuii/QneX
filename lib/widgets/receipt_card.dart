import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../models/transaction.dart';

/// Struk transaksi (dipakai di halaman sukses dan detail riwayat).
class ReceiptCard extends StatelessWidget {
  final TrxItem trx;
  const ReceiptCard({super.key, required this.trx});

  Widget _row(String label, String value,
      {bool bold = false, Color? color, double size = 13}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: size,
                  color: bold ? AppColors.ink : AppColors.muted,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  fontSize: size,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color ?? AppColors.ink)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ok = trx.status == TrxStatus.berhasil;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Struk Pembelian',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: ok ? AppColors.okBg : AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(ok ? 'Berhasil' : 'Gagal',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ok ? AppColors.ok : AppColors.danger)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('#${trx.id}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          Text(formatDate(trx.time),
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1E7C8)),
          ),
          if (trx.lines.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Rincian barang tidak tersedia untuk transaksi ini.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
            )
          else
            for (final l in trx.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${l.qty} × ${formatRupiah(l.price)}',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Text(formatRupiah(l.subtotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1E7C8)),
          ),
          _row('Total', formatRupiah(trx.amount),
              bold: true, size: 15, color: AppColors.orange),
          _row('Metode', trx.method),
          if (trx.cashReceived != null) ...[
            _row('Tunai diterima', formatRupiah(trx.cashReceived!)),
            _row('Kembalian', formatRupiah(trx.change)),
          ],
        ],
      ),
    );
  }
}
