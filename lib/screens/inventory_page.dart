import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../data/product_store.dart';
import '../models/product.dart';
import '../widgets/product_actions.dart';
import '../widgets/product_thumb.dart';
import '../widgets/qnex_bottom_bar.dart';
import 'product_detail_page.dart';
import 'product_form_page.dart';

const _bg = AppColors.cream;
const _line = AppColors.line;
const _amber = AppColors.amber;

enum InventoryFilter { all, low, expiring }

/// ---------- Halaman Inventori ----------
class InventoryPage extends StatefulWidget {
  final InventoryFilter initialFilter;
  const InventoryPage({super.key, this.initialFilter = InventoryFilter.all});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _store = ProductStore.instance;
  final DateTime _today = dateOnly(DateTime.now());
  late InventoryFilter _filter;
  String _query = '';

  List<Product> get _products => _store.products;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  bool _isExpiring(Product p) {
    final d = p.daysToExpiry(_today);
    return d != null && d <= 14; // sudah lewat atau kurang dari 2 minggu
  }

  List<Product> get _visible {
    final q = _query.trim().toLowerCase();
    Iterable<Product> list =
        _products.where((p) => p.name.toLowerCase().contains(q));
    if (_filter == InventoryFilter.low) {
      list = list.where((p) => p.isLow);
    } else if (_filter == InventoryFilter.expiring) {
      list = list.where(_isExpiring);
    }
    final out = list.toList();
    if (_filter == InventoryFilter.low) {
      out.sort((a, b) =>
          (a.stock / a.minStock).compareTo(b.stock / b.minStock));
    } else if (_filter == InventoryFilter.expiring) {
      out.sort((a, b) =>
          a.daysToExpiry(_today)!.compareTo(b.daysToExpiry(_today)!));
    }
    return out;
  }

  void _openDetail(Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
    );
  }

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormPage()),
    );
  }

  void _afterDelete(Product p) {
    _store.remove(p);
    showSnack(context, '${p.name} dihapus dari inventori');
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    final lowCount = _products.where((p) => p.isLow).length;
    final expCount = _products.where(_isExpiring).length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Inventori',
            style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        actions: [
          IconButton(
            onPressed: _openForm,
            tooltip: 'Tambah produk',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.orange),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari produk',
                hintStyle:
                    const TextStyle(color: AppColors.muted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.orange),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Filter: Semua / Stok Menipis / Kedaluwarsa
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _InvChip(
                  label: 'Semua',
                  count: _products.length,
                  selected: _filter == InventoryFilter.all,
                  onTap: () => setState(() => _filter = InventoryFilter.all),
                ),
                const SizedBox(width: 8),
                _InvChip(
                  label: 'Stok Menipis',
                  count: lowCount,
                  selected: _filter == InventoryFilter.low,
                  onTap: () => setState(() => _filter = InventoryFilter.low),
                ),
                const SizedBox(width: 8),
                _InvChip(
                  label: 'Kedaluwarsa',
                  count: expCount,
                  selected: _filter == InventoryFilter.expiring,
                  onTap: () =>
                      setState(() => _filter = InventoryFilter.expiring),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${items.length} produk',
                    style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const Text('Ketuk untuk detail • geser kiri untuk hapus',
                    style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 44, color: AppColors.muted),
                        SizedBox(height: 8),
                        Text('Produk tidak ditemukan',
                            style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final p = items[i];
                      return Dismissible(
                        key: ValueKey(p.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => confirmDeleteProduct(context, p),
                        onDismissed: (_) => _afterDelete(p),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.only(right: 24),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white),
                        ),
                        child: _ProductCard(
                          product: p,
                          today: _today,
                          onTap: () => _openDetail(p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButtonLocation: QnexCartFab.location,
      floatingActionButton: QnexCartFab(onPressed: () {}),
      bottomNavigationBar: QnexBottomBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) Navigator.of(context).popUntil((r) => r.isFirst);
          // TODO: tab lain
        },
      ),
    );
  }
}

/// ---------- Chip filter dengan jumlah ----------
class _InvChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _InvChip({
    required this.label,
    required this.count,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.orange : _line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.ink,
                  )),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withAlpha(70) : AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.orange,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Kartu produk ----------
class _ProductCard extends StatelessWidget {
  final Product product;
  final DateTime today;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.today,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final st = statusOf(product, today);
    final d = product.daysToExpiry(today);
    final ratio = (product.stock / product.capacity).clamp(0.0, 1.0).toDouble();

    String expText;
    Color expColor = AppColors.muted;
    if (d == null) {
      expText = 'Tanpa kedaluwarsa';
    } else if (d < 0) {
      expText = 'Kedaluwarsa ${-d} hari lalu';
      expColor = AppColors.danger;
    } else if (d == 0) {
      expText = 'Kedaluwarsa hari ini';
      expColor = AppColors.danger;
    } else if (d <= 14) {
      expText = 'Exp $d hari lagi';
      expColor = _amber;
    } else {
      expText = 'Exp ${formatDate(product.expiry!, withTime: false)}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                ProductThumb(product: product, size: 52, radius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: st.bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(st.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: st.fg,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                          '${product.category} • ${formatRupiah(product.price)}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11.5)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF3EEDB),
                          color: st.fg,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 11.5),
                              children: [
                                const TextSpan(
                                    text: 'Stok: ',
                                    style: TextStyle(color: AppColors.muted)),
                                TextSpan(
                                    text: '${product.stock}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          Text(expText,
                              style: TextStyle(color: expColor, fontSize: 11)),
                        ],
                      ),
                    ],
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
