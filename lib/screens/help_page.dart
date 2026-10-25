import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class _Faq {
  final String q;
  final String a;
  const _Faq(this.q, this.a);
}

const _faqs = [
  _Faq('Cara melayani pembeli',
      'Tekan tombol keranjang di tengah bar bawah, pilih barang dengan tombol +, '
      'lalu tekan Bayar. Pilih Tunai atau QRIS. Struk muncul setelah pembayaran berhasil.'),
  _Faq('Cara mengisi stok',
      'Buka Inventori, ketuk produknya, lalu tekan Stok Masuk. Isi jumlahnya dan simpan. '
      'Setiap stok masuk tercatat di tab Riwayat pada detail produk.'),
  _Faq('Cara menambah produk dan foto',
      'Di Inventori tekan ikon + di pojok kanan atas. Isi data produk, lalu tekan area foto '
      'untuk mengunggah gambar dari galeri atau kamera.'),
  _Faq('Cara menghapus produk',
      'Geser kartu produk ke kiri di Inventori, atau buka detail produk dan pilih '
      'Hapus produk di menu titik tiga. Penghapusan selalu meminta konfirmasi dulu.'),
  _Faq('Cara membaca laporan profit',
      'Profit adalah total penjualan dikurangi total modal. Buka Laporan Penjualan dari '
      'dashboard, lalu pilih minggu lewat kalender atau tombol panah.'),
  _Faq('Tentang pembayaran QRIS',
      'Saat ini QRIS masih mode simulasi untuk uji coba. Pembayaran sungguhan akan aktif '
      'setelah aplikasi terhubung ke Midtrans.'),
];

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: AppColors.cream,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Bantuan & Panduan',
            style: TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text('Pertanyaan yang sering muncul',
              style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const SizedBox(height: 12),
          for (final f in _faqs)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  iconColor: AppColors.orange,
                  collapsedIconColor: AppColors.muted,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(f.q,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  children: [
                    Text(f.a,
                        style: const TextStyle(fontSize: 12.5, height: 1.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
