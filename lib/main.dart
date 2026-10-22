import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ================= main.dart =================

void main() => runApp(const QnexApp());

class QnexApp extends StatelessWidget {
  const QnexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Q-NEX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orange),
        textTheme: GoogleFonts.montserratTextTheme(),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const OwnerDashboardPage(),
    );
  }
}

// ================= core/app_colors.dart =================

class AppColors {
  // Brand
  static const orange = Color(0xFFF26B3A);
  static const yellow = Color(0xFFF9C74F);
  static const gold = Color(0xFFF2B705);
  static const barBg = Color(0xFFFFEFB0);
  static const card = Color(0xFFFFF8E1);

  // Teks
  static const ink = Color(0xFF1F1F1F);
  static const muted = Color(0xFF8A8A8A);
  static const navy = Color(0xFF1F1F6B);
  static const idGrey = Color(0xFF9A9AB0);
  static const amountGrey = Color(0xFF5A5A7A);

  // Halaman riwayat transaksi
  static const bgSoft = Color(0xFFF8F8FF);
  static const border = Color(0xFFE9E9F5);
  static const chipOn = Color(0xFFF1E3A6);
  static const chipOff = Color(0xFFEAEAFB);

  // Status
  static const success = Color(0xFF6F7F1F);
  static const successBg = Color(0xFFEDE7A8);
  static const danger = Color(0xFFE5484D);
  static const dangerBg = Color(0xFFFBE0E3);
}

// ================= widgets/qnex_bottom_bar.dart =================

/// Cara pakai di Scaffold mana pun:
///
/// Scaffold(
///   floatingActionButtonLocation: QnexCartFab.location,
///   floatingActionButton: QnexCartFab(onPressed: () {}),
///   bottomNavigationBar: QnexBottomBar(currentIndex: 0, onTap: (i) {}),
///   ...
/// )
///
/// Index tab: 0 Home, 1 Wishlist, 3 Search, 4 Setting (2 = tombol keranjang).
class QnexBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const QnexBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.barBg,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              active: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.favorite_border,
              label: 'Wishlist',
              active: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            const Expanded(child: SizedBox()), // ruang untuk tombol keranjang
            _NavItem(
              icon: Icons.search,
              label: 'Search',
              active: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              label: 'Setting',
              active: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol keranjang bulat di tengah bottom bar.
class QnexCartFab extends StatelessWidget {
  final VoidCallback onPressed;
  const QnexCartFab({super.key, required this.onPressed});

  static const location = FloatingActionButtonLocation.centerDocked;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: const Icon(Icons.shopping_cart_outlined),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.orange : AppColors.ink;

    return Expanded(
      // InkResponse = efek ripple (gelombang) bulat saat ditekan
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        containedInkWell: false,
        highlightShape: BoxShape.circle,
        splashFactory: InkRipple.splashFactory,
        splashColor: AppColors.orange.withAlpha(75),
        highlightColor: AppColors.orange.withAlpha(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= screens/transaction_history_page.dart =================

enum TrxStatus { berhasil, gagal }

class TrxItem {
  final String id;
  final int amount;
  final String method;
  final DateTime time;
  final TrxStatus status;

  TrxItem(this.id, this.amount, this.method, this.time, this.status);
}

String _rupiah(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp $buf';
}

String _fmtDate(DateTime d) {
  const bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${bulan[d.month - 1]} ${d.year}, $hh:$mm';
}

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  // Data dummy (nanti diganti data dari database)
  final List<TrxItem> _all = [
    TrxItem(
      'TRX250412001',
      45000,
      'QRIS',
      DateTime(2025, 4, 12, 14, 32),
      TrxStatus.berhasil,
    ),
    TrxItem(
      'TRX250412000',
      25000,
      'Tunai',
      DateTime(2025, 4, 12, 13, 17),
      TrxStatus.berhasil,
    ),
    TrxItem(
      'TRX250411099',
      16000,
      'QRIS',
      DateTime(2025, 4, 11, 17, 45),
      TrxStatus.berhasil,
    ),
    TrxItem(
      'TRX250411098',
      32000,
      'Tunai',
      DateTime(2025, 4, 11, 16, 20),
      TrxStatus.berhasil,
    ),
    TrxItem(
      'TRX250411097',
      18000,
      'QRIS',
      DateTime(2025, 4, 11, 15, 52),
      TrxStatus.gagal,
    ),
  ];

  String _query = '';
  TrxStatus? _status; // null = Semua
  String? _method; // null = semua metode

  List<TrxItem> get _filtered {
    return _all.where((t) {
      final okQuery = t.id.toLowerCase().contains(_query.toLowerCase());
      final okStatus = _status == null || t.status == _status;
      final okMethod = _method == null || t.method == _method;
      return okQuery && okStatus && okMethod;
    }).toList();
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: const <String?>[null, 'QRIS', 'Tunai'].map((m) {
                return ChoiceChip(
                  label: Text(m ?? 'Semua'),
                  selected: _method == m,
                  selectedColor: AppColors.chipOn,
                  onSelected: (_) {
                    setState(() => _method = m);
                    Navigator.pop(sheetContext);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        backgroundColor: AppColors.bgSoft,
        surfaceTintColor: AppColors.bgSoft,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search + tombol filter
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi',
                      hintStyle: const TextStyle(
                        color: AppColors.idGrey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.navy,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.orange),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _openFilter,
                  icon: Icon(
                    Icons.filter_alt_outlined,
                    color: _method == null ? AppColors.navy : AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Chip status: Semua / Berhasil / Gagal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _FilterPill(
                  label: 'Semua',
                  selected: _status == null,
                  onTap: () => setState(() => _status = null),
                ),
                const SizedBox(width: 10),
                _FilterPill(
                  label: 'Berhasil',
                  selected: _status == TrxStatus.berhasil,
                  onTap: () => setState(() => _status = TrxStatus.berhasil),
                ),
                const SizedBox(width: 10),
                _FilterPill(
                  label: 'Gagal',
                  selected: _status == TrxStatus.gagal,
                  onTap: () => setState(() => _status = TrxStatus.gagal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Daftar transaksi
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Transaksi tidak ditemukan',
                      style: TextStyle(color: AppColors.idGrey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _TrxCard(item: items[i]),
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

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.chipOn : AppColors.chipOff,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 38,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.ink : AppColors.idGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrxCard extends StatelessWidget {
  final TrxItem item;
  const _TrxCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final ok = item.status == TrxStatus.berhasil;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {}, // TODO: buka detail transaksi
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${item.id}',
                        style: const TextStyle(
                          color: AppColors.idGrey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _rupiah(item.amount),
                        style: const TextStyle(
                          color: AppColors.amountGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.method} • ${_fmtDate(item.time)}',
                        style: const TextStyle(
                          color: AppColors.idGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ok ? AppColors.successBg : AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ok ? 'Berhasil' : 'Gagal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ok ? AppColors.success : AppColors.danger,
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

// ================= screens/owner_dashboard_page.dart =================

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
                onTap: () {},
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
            onAction: () {},
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
              onTap: () {},
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
