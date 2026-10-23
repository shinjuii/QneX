import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/qnex_bottom_bar.dart';
import 'inventory_page.dart';
import 'transaction_history_page.dart';

/// ---------- Data dummy (nanti diganti data asli dari database) ----------
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

  static const _summary = [
    _Stat('Penjualan Hari Ini', 'Rp 1.250.000', Icons.payments_outlined),
    _Stat('Transaksi', '38', Icons.receipt_long_outlined, toHistory: true),
    _Stat('Produk Terjual', '126', Icons.shopping_bag_outlined),
    _Stat('Stok Menipis', '5', Icons.warning_amber_rounded),
  ];

  static const _lowStock = [
    _LowStock('Kopi Susu Botol', 3, 30),
    _LowStock('Roti Coklat', 5, 40),
    _LowStock('Air Mineral 600ml', 8, 60),
  ];

  static const _recent = [
    _RecentTrx('TRX250412001', 'Rp 45.000', 'QRIS • 14:32', true),
    _RecentTrx('TRX250412000', 'Rp 25.000', 'Tunai • 13:17', true),
    _RecentTrx('TRX250411097', 'Rp 18.000', 'QRIS • 15:52', false),
  ];

  void _openInventory({InventoryFilter filter = InventoryFilter.all}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InventoryPage(initialFilter: filter)),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionHistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            'Halo, Owner',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          const Text(
            'Ini ringkasan usahamu hari ini.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
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
            children: _summary
                .map(
                  (s) => _StatCard(
                    stat: s,
                    onTap: s.toHistory ? _openHistory : null,
                  ),
                )
                .toList(),
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
                onTap: () {},
              ),
              _QuickAction(
                icon: Icons.inventory_2_outlined,
                label: 'Isi\nStok',
                onTap: _openInventory,
              ),
              _QuickAction(
                icon: Icons.group_outlined,
                label: 'Kelola\nKaryawan',
                onTap: () {},
              ),
              _QuickAction(
                icon: Icons.bar_chart_rounded,
                label: 'Laporan\nPenjualan',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            'Transaksi Terbaru',
            actionLabel: 'Lihat semua',
            onAction: _openHistory,
          ),
          const SizedBox(height: 12),
          ..._recent.map((t) => _RecentTrxTile(item: t, onTap: _openHistory)),
          const SizedBox(height: 14),
          _SectionTitle(
            'Stok Menipis',
            actionLabel: 'Lihat semua',
            onAction: () => _openInventory(filter: InventoryFilter.low),
          ),
          const SizedBox(height: 12),
          ..._lowStock.map((item) => _LowStockTile(item: item)),
        ],
      ),

      // Bottom bar sekarang tinggal dipanggil
      floatingActionButtonLocation: QnexCartFab.location,
      floatingActionButton: QnexCartFab(onPressed: () {}),
      bottomNavigationBar: QnexBottomBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// ---------- Komponen-komponen ----------
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    // Placeholder. Ganti dengan Image.asset('assets/logo.png') kalau sudah ada file logonya.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Q',
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Q-NEX',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
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
                const Text(
                  'Temukan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tempat Strategis\nUntuk Jualanmu',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MAPS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Placeholder gambar HP di Figma. Ganti dengan Image.asset(...) nanti.
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
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.orange,
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      stat.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Text(
                    stat.label,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
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
                      Text(
                        '#${item.id}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.amount,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.info,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.success
                        ? AppColors.successBg
                        : AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.success ? 'Berhasil' : 'Gagal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: item.success
                          ? AppColors.success
                          : AppColors.danger,
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, height: 1.2),
            ),
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
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                'Sisa ${item.left}',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: item.left / item.max,
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
            const Padding(padding: EdgeInsets.all(20), child: _Logo()),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Produk & Stok'),
              onTap: () {
                Navigator.pop(context); // tutup drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Riwayat Transaksi'),
              onTap: () {
                Navigator.pop(context); // tutup drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionHistoryPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_outlined),
              title: const Text('Karyawan'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded),
              title: const Text('Laporan'),
              onTap: () {},
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Keluar'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
