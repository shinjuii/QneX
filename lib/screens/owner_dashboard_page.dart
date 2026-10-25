import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../widgets/qnex_bottom_bar.dart';
import '../data/session_store.dart';
import '../data/product_store.dart';
import '../models/product.dart';
import '../widgets/logout.dart';
import 'inventory_page.dart';
import 'product_form_page.dart';
import 'transaction_history_page.dart';
import 'weekly_report_page.dart';

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final bool toHistory;
  const _Stat(this.label, this.value, this.icon, {this.toHistory = false});
}

class _RecentTrx {
  final String id;
  final String amount;
  final String info;
  final bool success;
  const _RecentTrx(this.id, this.amount, this.info, this.success);
}

class _LowStock {
  final String name;
  final int left;
  final int max;
  const _LowStock(this.name, this.left, this.max);
}

/// ---------- Halaman Dashboard Owner ----------
class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  int _tab = 0;
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProductStore _productStore = ProductStore.instance;

  double _todaySales = 0;
  int _todayTxCount = 0;
  int _todayItemsSold = 0;
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _productStore.addListener(_onStoreChanged);
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _productStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

      // 1. Ambil transaksi hari ini dari Supabase
      final txResponse = await _supabase
          .from('transactions')
          .select('id, total_amount, payment_method, status, created_at')
          .gte('created_at', startOfDay)
          .order('created_at', ascending: false);

      double salesSum = 0;
      int txCount = txResponse.length;
      List<String> todayTxIds = [];

      for (var tx in txResponse) {
        if (tx['status'] == 'Berhasil') {
          salesSum += (tx['total_amount'] as num?)?.toDouble() ?? 0;
          todayTxIds.add(tx['id'].toString());
        }
      }

      // 2. Hitung jumlah produk terjual hari ini dari transaction_items
      int itemsSold = 0;
      if (todayTxIds.isNotEmpty) {
        final itemsResponse = await _supabase
            .from('transaction_items')
            .select('qty')
            .inFilter('transaction_id', todayTxIds);
        for (var item in itemsResponse) {
          itemsSold += (item['qty'] as num?)?.toInt() ?? 0;
        }
      }

      // 3. Ambil daftar transaksi terbaru (untuk list)
      final recentResponse = await _supabase
          .from('transactions')
          .select('id, total_amount, payment_method, status, created_at')
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        _todaySales = salesSum;
        _todayTxCount = txCount;
        _todayItemsSold = itemsSold;
        _recentTransactions = List<Map<String, dynamic>>.from(recentResponse);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat data dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  void _openInventory({InventoryFilter filter = InventoryFilter.all}) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => InventoryPage(initialFilter: filter)),
    ).then((_) => _fetchDashboardData());
  }

  void _openProductForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormPage()),
    ).then((_) => _fetchDashboardData());
  }

  void _openReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WeeklyReportPage()),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionHistoryPage()),
    ).then((_) => _fetchDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data produk stok menipis langsung dari ProductStore yang sama dengan Inventori
    final lowStockProducts = _productStore.products.where((p) => p.isLow).toList();

    return Scaffold(
      drawer: const _OwnerDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const _Logo(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.orange,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _productStore.loadProducts();
          await _fetchDashboardData();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            Text('Halo, ${SessionStore.instance.current.name}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            const Text('Ini ringkasan usahamu hari ini.',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 16),
            const _PromoBanner(),
            const SizedBox(height: 24),
            const _SectionTitle('Ringkasan Hari Ini'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  stat: _Stat(
                    'Penjualan Hari Ini',
                    formatRupiah(_todaySales.toInt()),
                    Icons.payments_outlined,
                  ),
                ),
                _StatCard(
                  stat: _Stat(
                    'Transaksi',
                    '$_todayTxCount',
                    Icons.receipt_long_outlined,
                    toHistory: true,
                  ),
                  onTap: _openHistory,
                ),
                _StatCard(
                  stat: _Stat(
                    'Produk Terjual',
                    '$_todayItemsSold',
                    Icons.shopping_bag_outlined,
                  ),
                ),
                _StatCard(
                  stat: _Stat(
                    'Stok Menipis',
                    '${lowStockProducts.length}',
                    Icons.warning_amber_rounded,
                    toHistory: true,
                  ),
                  onTap: () => _openInventory(filter: InventoryFilter.low),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Menu Cepat'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuickAction(
                    icon: Icons.add_box_outlined,
                    label: 'Tambah\nProduk',
                    onTap: _openProductForm),
                _QuickAction(
                    icon: Icons.inventory_2_outlined,
                    label: 'Isi\nStok',
                    onTap: _openInventory),
                _QuickAction(
                    icon: Icons.group_outlined,
                    label: 'Kelola\nKaryawan',
                    onTap: () {}),
                _QuickAction(
                    icon: Icons.bar_chart_rounded,
                    label: 'Laporan\nPenjualan',
                    onTap: _openReport),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle('Transaksi Terbaru',
                actionLabel: 'Lihat semua', onAction: _openHistory),
            const SizedBox(height: 12),
            if (_recentTransactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: Text('Belum ada transaksi',
                        style: TextStyle(color: AppColors.muted))),
              )
            else
              ..._recentTransactions.map((t) {
                final isSuccess = t['status'] == 'Berhasil';
                final amount = formatRupiah(
                    (t['total_amount'] as num?)?.toInt() ?? 0);
                final method = t['payment_method'] ?? 'Tunai';
                return _RecentTrxTile(
                  item: _RecentTrx(t['id'].toString(), amount, method, isSuccess),
                  onTap: _openHistory,
                );
              }),
            const SizedBox(height: 14),
            _SectionTitle('Stok Menipis',
                actionLabel: 'Lihat semua',
                onAction: () => _openInventory(filter: InventoryFilter.low)),
            const SizedBox(height: 12),
            if (lowStockProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: Text('Semua stok aman',
                        style: TextStyle(color: AppColors.muted))),
              )
            else
              ...lowStockProducts.take(3).map((p) => _LowStockTile(
                item: _LowStock(p.name, p.stock, p.capacity > 0 ? p.capacity : 50),
              )),
          ],
        ),
      ),
      floatingActionButtonLocation: QnexCartFab.location,
      floatingActionButton: const QnexCartFab(),
      bottomNavigationBar: QnexBottomBar(
        currentIndex: _tab,
        onTap: (i) {
          if (i == 4) {
            qnexGoTo(context, i);
          } else {
            setState(() => _tab = i);
          }
        },
      ),
    );
  }
}

/// ---------- Komponen-komponen Pendukung ----------
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('Q',
              style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
        ),
        const SizedBox(width: 6),
        const Text('Q-NEX',
            style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange, AppColors.yellow],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Temukan',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20)),
                const SizedBox(height: 2),
                const Text('Tempat Strategis\nUntuk Jualanmu',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('MAPS',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.phone_android, size: 90, color: Colors.white70),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionTitle(this.title, {this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!,
                style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final _Stat stat;
  final VoidCallback? onTap;
  const _StatCard({required this.stat, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(stat.icon, color: AppColors.orange, size: 22),
                  if (onTap != null)
                    const Icon(Icons.arrow_forward_ios,
                        size: 12, color: AppColors.orange),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(stat.value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                  Text(stat.label,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTrxTile extends StatelessWidget {
  final _RecentTrx item;
  final VoidCallback onTap;
  const _RecentTrxTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEFEFEF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${item.id}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(item.amount,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(item.info,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.success
                        ? AppColors.successBg
                        : AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item.success ? 'Berhasil' : 'Gagal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.success
                            ? AppColors.success
                            : AppColors.danger,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.orange),
            ),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  final _LowStock item;
  const _LowStockTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text('Sisa ${item.left}',
                  style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (item.left / item.max).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F1F1),
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerDrawer extends StatelessWidget {
  const _OwnerDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: _Logo(),
            ),
            const Divider(height: 1),
            ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Produk & Stok'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryPage()),
                  );
                }),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Riwayat Transaksi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TransactionHistoryPage()),
                );
              },
            ),
            ListTile(
                leading: const Icon(Icons.group_outlined),
                title: const Text('Karyawan'),
                onTap: () {}),
            ListTile(
                leading: const Icon(Icons.bar_chart_rounded),
                title: const Text('Laporan'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WeeklyReportPage()),
                  );
                }),
            const Spacer(),
            ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text('Keluar'),
                onTap: () => confirmAndLogout(context)),
          ],
        ),
      ),
    );
  }
}