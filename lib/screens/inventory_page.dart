import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/qnex_bottom_bar.dart';

const _bg = Color(0xFFFFFBEF);
const _line = Color(0xFFF3E3A8);
const _ok = Color(0xFF2E9E5B);
const _okBg = Color(0xFFE3F5EA);
const _warnBg = Color(0xFFFFE8D9);
const _amber = Color(0xFFB7791F);
const _amberBg = Color(0xFFFFF1C9);

enum InventoryFilter { all, low, expiring }

/// ---------- Model produk (data dummy, nanti dari database) ----------
class Product {
  final String name;
  final String category;
  final int price;
  int stock;
  final int minStock; // di bawah/sama dengan ini = "Minim"
  final int capacity; // stok penuh, untuk panjang bar
  final DateTime? expiry;
  final IconData icon;

  Product(
    this.name,
    this.category,
    this.price,
    this.stock,
    this.minStock,
    this.capacity,
    this.expiry,
    this.icon,
  );

  bool get isLow => stock <= minStock;

  int? daysToExpiry(DateTime today) => expiry?.difference(today).inDays;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

List<Product> _dummyProducts(DateTime today) {
  DateTime inDays(int n) => DateTime(today.year, today.month, today.day + n);
  return [
    Product(
      'Indomie Goreng',
      'Makanan',
      3500,
      48,
      20,
      120,
      inDays(120),
      Icons.ramen_dining,
    ),
    Product(
      'Susu UHT Cokelat 200ml',
      'Minuman',
      6500,
      32,
      12,
      60,
      inDays(9),
      Icons.local_drink,
    ),
    Product(
      'Teh Botol 450ml',
      'Minuman',
      5000,
      4,
      12,
      48,
      inDays(200),
      Icons.emoji_food_beverage,
    ),
    Product('Gula Pasir 1kg', 'Sembako', 17000, 6, 10, 40, null, Icons.grain),
    Product(
      'Minyak Goreng 1L',
      'Sembako',
      18500,
      22,
      10,
      40,
      inDays(300),
      Icons.opacity,
    ),
    Product(
      'Kopi Susu Botol',
      'Minuman',
      12000,
      3,
      10,
      30,
      inDays(20),
      Icons.coffee,
    ),
    Product(
      'Roti Coklat',
      'Makanan',
      8000,
      5,
      10,
      40,
      inDays(2),
      Icons.bakery_dining,
    ),
    Product(
      'Air Mineral 600ml',
      'Minuman',
      4000,
      8,
      15,
      60,
      inDays(400),
      Icons.water_drop,
    ),
    Product(
      'Biskuit Kelapa',
      'Makanan',
      9000,
      30,
      10,
      50,
      inDays(-3),
      Icons.cookie,
    ),
  ];
}

/// ---------- Status produk ----------
class _Status {
  final String label;
  final Color fg;
  final Color bg;
  const _Status(this.label, this.fg, this.bg);
}

_Status _statusOf(Product p, DateTime today) {
  final d = p.daysToExpiry(today);
  if (d != null && d < 0) {
    return const _Status('Kedaluwarsa', AppColors.danger, AppColors.dangerBg);
  }
  if (p.isLow) return const _Status('Minim', AppColors.orange, _warnBg);
  if (d != null && d <= 14)
    return const _Status('Hampir exp', _amber, _amberBg);
  return const _Status('Aman', _ok, _okBg);
}

/// ---------- Halaman Inventori ----------
class InventoryPage extends StatefulWidget {
  final InventoryFilter initialFilter;
  const InventoryPage({super.key, this.initialFilter = InventoryFilter.all});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final DateTime _today = _dateOnly(DateTime.now());
  late final List<Product> _products = _dummyProducts(_today);
  late InventoryFilter _filter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  bool _isExpiring(Product p) {
    final d = p.daysToExpiry(_today);
    return d != null && d <= 14; // sudah lewat atau kurang dari 2 minggu
  }

  List<Product> get _visible {
    final q = _query.trim().toLowerCase();
    Iterable<Product> list = _products.where(
      (p) => p.name.toLowerCase().contains(q),
    );
    if (_filter == InventoryFilter.low) {
      list = list.where((p) => p.isLow);
    } else if (_filter == InventoryFilter.expiring) {
      list = list.where(_isExpiring);
    }
    final out = list.toList();
    if (_filter == InventoryFilter.low) {
      out.sort(
        (a, b) => (a.stock / a.minStock).compareTo(b.stock / b.minStock),
      );
    } else if (_filter == InventoryFilter.expiring) {
      out.sort(
        (a, b) => a.daysToExpiry(_today)!.compareTo(b.daysToExpiry(_today)!),
      );
    }
    return out;
  }

  Future<void> _restock(Product p) async {
    final added = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RestockSheet(product: p),
    );
    if (added != null && added > 0 && mounted) {
      setState(() => p.stock += added);
      showSnack(
        context,
        'Stok ${p.name} bertambah $added (sekarang ${p.stock})',
      );
    }
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
        title: const Text(
          'Inventori',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
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
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                ),
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
                  borderSide: const BorderSide(
                    color: AppColors.gold,
                    width: 1.8,
                  ),
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
                Text(
                  '${items.length} produk',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Ketuk produk untuk isi stok',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
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
                        Icon(
                          Icons.inventory_2_outlined,
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ProductCard(
                      product: items[i],
                      today: _today,
                      onTap: () => _restock(items[i]),
                    ),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withAlpha(70) : AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.orange,
                  ),
                ),
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
    final st = _statusOf(product, today);
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
                // Placeholder foto produk. Nanti ganti dengan Image dari database.
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(product.icon, color: AppColors.orange, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: st.bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              st.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: st.fg,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product.category} • ${formatRupiah(product.price)}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                        ),
                      ),
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
                                  style: TextStyle(color: AppColors.muted),
                                ),
                                TextSpan(
                                  text: '${product.stock}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            expText,
                            style: TextStyle(color: expColor, fontSize: 11),
                          ),
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

/// ---------- Bottom sheet isi stok (khusus owner) ----------
class _RestockSheet extends StatefulWidget {
  final Product product;
  const _RestockSheet({required this.product});

  @override
  State<_RestockSheet> createState() => _RestockSheetState();
}

class _RestockSheetState extends State<_RestockSheet> {
  final _ctrl = TextEditingController(text: '10');

  int get _qty => int.tryParse(_ctrl.text) ?? 0;

  void _set(int v) {
    final n = v < 0 ? 0 : (v > 9999 ? 9999 : v);
    setState(() {
      _ctrl.text = '$n';
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(p.icon, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Stok saat ini: ${p.stock}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Jumlah stok masuk',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _RoundBtn(icon: Icons.remove, onTap: () => _set(_qty - 1)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
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
              const SizedBox(width: 12),
              _RoundBtn(icon: Icons.add, onTap: () => _set(_qty + 1)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [10, 20, 50]
                .map(
                  (n) => ActionChip(
                    label: Text('+$n'),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: _line),
                    onPressed: () => _set(_qty + n),
                  ),
                )
                .toList(),
          ),
          if (_qty == 0)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Masukkan jumlah lebih dari 0',
                style: TextStyle(color: AppColors.danger, fontSize: 11),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Stok setelah diisi',
                  style: TextStyle(fontSize: 12.5),
                ),
                Text(
                  '${p.stock}  →  ${p.stock + _qty}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Simpan Stok',
            onPressed: () {
              if (_qty > 0) Navigator.pop(context, _qty);
            },
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: AppColors.orange),
        ),
      ),
    );
  }
}
