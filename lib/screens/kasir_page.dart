import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../data/cart_controller.dart';
import '../data/product_store.dart';
import '../models/product.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/product_thumb.dart';
import 'payment_page.dart';
import 'transaction_history_page.dart';

const _brown = Color(0xFF5A3A1A);

/// Halaman kasir: pilih barang yang dibeli, lalu lanjut ke pembayaran.
class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  static const _cats = ['Semua', 'Minuman', 'Makanan', 'Lainnya'];

  final _store = ProductStore.instance;
  final _cart = CartController();
  final DateTime _today = dateOnly(DateTime.now());
  String _query = '';
  String _cat = 'Semua';

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    _cart.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    _cart.removeListener(_refresh);
    _cart.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool _isExpired(Product p) => (p.daysToExpiry(_today) ?? 1) < 0;

  List<Product> get _visible {
    final q = _query.trim().toLowerCase();
    return _store.products.where((p) {
      final okQuery = p.name.toLowerCase().contains(q);
      final okCat =
          _cat == 'Semua' ||
          (_cat == 'Lainnya'
              ? (p.category != 'Minuman' && p.category != 'Makanan')
              : p.category == _cat);
      return okQuery && okCat;
    }).toList();
  }

  void _add(Product p) {
    if (!_cart.add(p)) {
      showSnack(context, 'Stok ${p.name} tinggal ${p.stock} ${p.unit}');
    }
  }

  void _checkout() {
    if (_cart.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentPage(cart: _cart)),
    );
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CartSheet(
        cart: _cart,
        onPay: () {
          Navigator.pop(context); // tutup keranjang
          _checkout();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: AppColors.cream,
        elevation: 0,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 1.5,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: const Icon(Icons.arrow_back, color: AppColors.ink),
            ),
          ),
        ),
        title: const Text(
          'Kasir / POS',
          style: TextStyle(
            color: AppColors.orange,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Riwayat transaksi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionHistoryPage()),
            ),
            icon: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Pencarian + scan
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.orange),
                suffixIcon: IconButton(
                  tooltip: 'Scan barcode',
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.muted,
                  ),
                  onPressed: () => showSnack(
                    context,
                    'Scan barcode akan aktif setelah produk punya kode barcode.',
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.gold,
                    width: 1.8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Kategori
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                for (final c in _cats) ...[
                  _CatChip(
                    label: c,
                    selected: _cat == c,
                    onTap: () => setState(() => _cat = c),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 44,
                          color: AppColors.muted,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Produk tidak ditemukan',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      _cart.isEmpty ? 24 : 12,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final p = items[i];
                      return _KasirTile(
                        product: p,
                        qty: _cart.qtyOf(p),
                        expired: _isExpired(p),
                        onAdd: () => _add(p),
                        onMinus: () => _cart.decrement(p),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Ringkasan keranjang muncul kalau sudah ada barang
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: _cart.isEmpty
            ? const SizedBox(width: double.infinity)
            : _CartBar(cart: _cart, onOpen: _openCart, onPay: _checkout),
      ),
    );
  }
}

/// ---------- Komponen ----------
class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orange : Colors.white,
      animationDuration: const Duration(milliseconds: 200),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _KasirTile extends StatelessWidget {
  final Product product;
  final int qty;
  final bool expired;
  final VoidCallback onAdd;
  final VoidCallback onMinus;

  const _KasirTile({
    required this.product,
    required this.qty,
    required this.expired,
    required this.onAdd,
    required this.onMinus,
  });

  @override
  Widget build(BuildContext context) {
    final soldOut = product.stock <= 0;
    final blocked = soldOut || expired;

    String stockText;
    Color stockColor;
    if (expired) {
      stockText = 'Kedaluwarsa';
      stockColor = AppColors.danger;
    } else if (soldOut) {
      stockText = 'Stok habis';
      stockColor = AppColors.danger;
    } else {
      stockText = 'Stok: ${product.stock}';
      stockColor = product.isLow ? AppColors.orange : AppColors.ok;
    }

    return Opacity(
      opacity: blocked ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: qty > 0 ? AppColors.orange : AppColors.line,
            width: qty > 0 ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            ProductThumb(product: product, size: 62, radius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatRupiah(product.price),
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stockText,
                    style: TextStyle(
                      color: stockColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (blocked)
              const Icon(Icons.block, color: AppColors.muted)
            else if (qty == 0)
              Material(
                color: AppColors.card,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onAdd,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.add, color: AppColors.orange),
                  ),
                ),
              )
            else
              _Stepper(
                qty: qty,
                canAdd: qty < product.stock,
                onMinus: onMinus,
                onAdd: onAdd,
              ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int qty;
  final bool canAdd;
  final VoidCallback onMinus;
  final VoidCallback onAdd;

  const _Stepper({
    required this.qty,
    required this.canAdd,
    required this.onMinus,
    required this.onAdd,
  });

  Widget _btn(IconData icon, VoidCallback onTap, {bool enabled = true}) {
    return Material(
      color: enabled ? AppColors.orange : const Color(0xFFE5DFC9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, onMinus),
          SizedBox(
            width: 30,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          _btn(Icons.add, onAdd, enabled: canAdd),
        ],
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  final CartController cart;
  final VoidCallback onOpen;
  final VoidCallback onPay;

  const _CartBar({
    required this.cart,
    required this.onOpen,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF26B3A), Color(0xFFF59A3B)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onOpen,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(60),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_basket_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${cart.itemCount} item • lihat keranjang',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  formatRupiah(cart.total),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: onPay,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bayar',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: AppColors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartSheet extends StatelessWidget {
  final CartController cart;
  final VoidCallback onPay;
  const _CartSheet({required this.cart, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (ctx, _) {
        final lines = cart.lines;
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E4E4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Keranjang (${cart.itemCount} item)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (lines.isNotEmpty)
                      TextButton(
                        onPressed: cart.clear,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                        child: const Text('Kosongkan'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (lines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Keranjang kosong',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  )
                else ...[
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: lines.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF5EDD2)),
                      itemBuilder: (_, i) {
                        final l = lines[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              ProductThumb(
                                product: l.product,
                                size: 46,
                                radius: 12,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      formatRupiah(l.subtotal),
                                      style: const TextStyle(
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _Stepper(
                                qty: l.qty,
                                canAdd: l.qty < l.product.stock,
                                onMinus: () => cart.decrement(l.product),
                                onAdd: () => cart.add(l.product),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        formatRupiah(cart.total),
                        style: const TextStyle(
                          color: _brown,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GradientButton(label: 'Lanjut Bayar', onPressed: onPay),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
