import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../data/product_store.dart';
import '../models/product.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/photo_picker.dart';
import '../widgets/product_actions.dart';
import '../widgets/product_thumb.dart';
import 'product_form_page.dart';

const _brown = Color(0xFF5A3A1A);

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _store = ProductStore.instance;
  final DateTime _today = dateOnly(DateTime.now());
  int _tab = 0;

  Product get _p => widget.product;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _changePhoto() async {
    final bytes = await pickProductPhoto(context);
    if (bytes != null && mounted) {
      _store.setPhoto(_p, bytes);
      showSnack(context, 'Foto produk diperbarui');
    }
  }

  void _removePhoto() {
    _store.setPhoto(_p, null);
    showSnack(context, 'Foto produk dihapus');
  }

  void _edit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormPage(product: _p)),
    );
  }

  Future<void> _delete() async {
    final ok = await confirmDeleteProduct(context, _p);
    if (!ok || !mounted) return;
    final name = _p.name;
    _store.remove(_p);
    showSnack(context, '$name dihapus dari inventori');
    Navigator.pop(context);
  }

  List<_Alert> _alerts() {
    final out = <_Alert>[];
    final d = _p.daysToExpiry(_today);
    if (d != null && d < 0) {
      out.add(_Alert(Icons.error_outline, 'Produk kedaluwarsa',
          'Sudah lewat ${-d} hari. Segera tarik dari rak.',
          AppColors.danger, AppColors.dangerBg));
    } else if (d != null && d <= 14) {
      out.add(_Alert(
          Icons.schedule,
          'Hampir kedaluwarsa',
          d == 0
              ? 'Kedaluwarsa hari ini. Prioritaskan penjualan.'
              : 'Kedaluwarsa $d hari lagi. Prioritaskan penjualan.',
          AppColors.amber,
          AppColors.amberBg));
    }
    if (_p.isLow) {
      out.add(_Alert(
          Icons.warning_amber_rounded,
          'Stok minim',
          'Sisa ${_p.stock} ${_p.unit}, di bawah batas minimum ${_p.minStock}. '
              'Segera isi stok.',
          AppColors.orange,
          AppColors.warnBg,
          canRestock: true));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final st = statusOf(p, _today);
    final alerts = _alerts();

    return Scaffold(
      backgroundColor: AppColors.cream,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _edit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    side: const BorderSide(color: AppColors.orange, width: 1.5),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: GradientButton(
                  label: 'Stok Masuk',
                  onPressed: () => showRestockSheet(context, p),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.orange, AppColors.yellow],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 60,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text('Detail Produk',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onSelected: (v) {
                        if (v == 'edit') _edit();
                        if (v == 'photo') _changePhoto();
                        if (v == 'rmphoto') _removePhoto();
                        if (v == 'delete') _delete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: _MenuRow(Icons.edit_outlined, 'Edit produk'),
                        ),
                        const PopupMenuItem(
                          value: 'photo',
                          child: _MenuRow(
                              Icons.photo_camera_outlined, 'Ubah foto'),
                        ),
                        if (p.photo != null)
                          const PopupMenuItem(
                            value: 'rmphoto',
                            child: _MenuRow(
                                Icons.hide_image_outlined, 'Hapus foto'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: _MenuRow(Icons.delete_outline, 'Hapus produk',
                              color: AppColors.danger),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                // Foto + nama + harga
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ProductThumb(product: p, size: 96, radius: 22),
                        ),
                        Positioned(
                          right: -6,
                          bottom: -6,
                          child: Material(
                            color: AppColors.orange,
                            shape: const CircleBorder(
                              side: BorderSide(color: Colors.white, width: 2),
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _changePhoto,
                              child: const SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(Icons.camera_alt,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 2),
                          Text(p.category,
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(fontSize: 12.5),
                                children: [
                                  const TextSpan(
                                      text: 'Harga  ',
                                      style:
                                          TextStyle(color: AppColors.muted)),
                                  TextSpan(
                                      text: formatRupiah(p.price),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.orange)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Kartu stok
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD27A), Color(0xFFF9B233)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withAlpha(70),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stok tersedia',
                                  style: TextStyle(
                                      color: _brown,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${p.stock}',
                                      style: const TextStyle(
                                          color: _brown,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800),
                                    ),
                                    TextSpan(
                                      text: '  ${p.unit}',
                                      style: const TextStyle(
                                          color: _brown,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          _StatusBadge(status: st),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _StockBar(
                        stock: p.stock,
                        min: p.minStock,
                        capacity: p.capacity,
                        fill: st.label == 'Normal'
                            ? AppColors.ok
                            : (st.label == 'Hampir exp'
                                ? AppColors.amber
                                : AppColors.danger),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Tab
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      _TabBtn(
                        label: 'Detail',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      _TabBtn(
                        label: 'Riwayat',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                      _TabBtn(
                        label: 'Peringatan',
                        badge: alerts.length,
                        selected: _tab == 2,
                        onTap: () => setState(() => _tab = 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_tab),
                    child: _tab == 0
                        ? _detailTab()
                        : (_tab == 1 ? _historyTab() : _alertsTab(alerts)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Tab Detail ----------
  Widget _detailTab() {
    final p = _p;
    final profit = p.price - p.costPrice;
    final margin = p.price > 0 ? (profit / p.price * 100).round() : 0;

    final rows = <_RowData>[
      _RowData('Harga Modal', formatRupiah(p.costPrice)),
      _RowData('Keuntungan / unit',
          '${formatRupiah(profit)}  ($margin%)',
          color: profit > 0 ? AppColors.ok : AppColors.danger),
      _RowData('Tanggal Masuk', formatDate(p.entryDate, withTime: false)),
      _RowData('Tanggal Kedaluwarsa',
          p.expiry == null ? '-' : formatDate(p.expiry!, withTime: false)),
      _RowData('Lokasi Stok', p.location.isEmpty ? '-' : p.location),
      _RowData('Stok Minimum', '${p.minStock} ${p.unit}'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rows[i].label,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 13)),
                  Text(rows[i].value,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: rows[i].color ?? AppColors.ink)),
                ],
              ),
            ),
            if (i != rows.length - 1)
              const Divider(height: 1, color: Color(0xFFF5EDD2)),
          ],
        ],
      ),
    );
  }

  // ---------- Tab Riwayat ----------
  Widget _historyTab() {
    final logs = _p.history;
    if (logs.isEmpty) {
      return const _EmptyBox(
          icon: Icons.history, text: 'Belum ada riwayat stok');
    }
    return Column(
      children: [
        for (final log in logs)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: log.qty >= 0 ? AppColors.okBg : AppColors.dangerBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    log.qty >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 18,
                    color: log.qty >= 0 ? AppColors.ok : AppColors.danger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.note,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(formatDate(log.date),
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  '${log.qty >= 0 ? '+' : ''}${log.qty} ${_p.unit}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: log.qty >= 0 ? AppColors.ok : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------- Tab Peringatan ----------
  Widget _alertsTab(List<_Alert> alerts) {
    if (alerts.isEmpty) {
      return const _EmptyBox(
        icon: Icons.check_circle_outline,
        text: 'Tidak ada peringatan.\nStok produk ini aman.',
        color: AppColors.ok,
      );
    }
    return Column(
      children: [
        for (final a in alerts)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: a.bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(a.icon, color: a.fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title,
                          style: TextStyle(
                              color: a.fg,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(a.message,
                          style: const TextStyle(fontSize: 12, height: 1.35)),
                      if (a.canRestock)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: TextButton(
                            onPressed: () => showRestockSheet(context, _p),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: a.fg,
                            ),
                            child: const Text('Isi stok sekarang',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// ---------- Komponen kecil ----------
class _RowData {
  final String label;
  final String value;
  final Color? color;
  const _RowData(this.label, this.value, {this.color});
}

class _Alert {
  final IconData icon;
  final String title;
  final String message;
  final Color fg;
  final Color bg;
  final bool canRestock;
  const _Alert(this.icon, this.title, this.message, this.fg, this.bg,
      {this.canRestock = false});
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MenuRow(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? AppColors.ink),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 13.5)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProductStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: status.fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(status.label,
              style: TextStyle(
                  color: status.fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _StockBar extends StatelessWidget {
  final int stock;
  final int min;
  final int capacity;
  final Color fill;

  const _StockBar({
    required this.stock,
    required this.min,
    required this.capacity,
    required this.fill,
  });

  @override
  Widget build(BuildContext context) {
    const labelStyle =
        TextStyle(color: _brown, fontSize: 11, fontWeight: FontWeight.w600);

    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      final cap = capacity <= 0 ? 1 : capacity;
      final ratio = (stock / cap).clamp(0.0, 1.0).toDouble();
      final minRatio = (min / cap).clamp(0.0, 1.0).toDouble();
      final hi = w - 96 < 16 ? 16.0 : w - 96;
      final labelLeft = (w * minRatio - 40).clamp(16.0, hi).toDouble();

      return Column(
        children: [
          SizedBox(
            height: 14,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(150),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                  height: 10,
                  width: w * ratio,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Positioned(
                  left: w * minRatio - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: _brown.withAlpha(150)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 16,
            child: Stack(
              children: [
                const Positioned(left: 0, child: Text('0', style: labelStyle)),
                Positioned(
                  left: labelLeft,
                  width: 80,
                  child: Text('Minimum $min',
                      textAlign: TextAlign.center, style: labelStyle),
                ),
                Positioned(
                    right: 0, child: Text('$capacity', style: labelStyle)),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.orange : Colors.transparent,
        animationDuration: const Duration(milliseconds: 200),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.muted,
                    )),
                if (badge > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$badge',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: selected ? AppColors.orange : Colors.white,
                        )),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _EmptyBox(
      {required this.icon, required this.text, this.color = AppColors.muted});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
