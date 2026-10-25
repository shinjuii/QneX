import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../data/report.dart';
import '../data/transaction_store.dart';
import '../models/product.dart' show dateOnly;

const _dayNames = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
];
const _dayShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String _compact(int v) {
  if (v >= 1000000) {
    final s = (v / 1000000).toStringAsFixed(1);
    return 'Rp ${s.endsWith('.0') ? s.substring(0, s.length - 2) : s.replaceAll('.', ',')}jt';
  }
  if (v >= 1000) return 'Rp ${(v / 1000).round()}rb';
  return 'Rp $v';
}

String _num(int v) => formatRupiah(v).replaceFirst('Rp ', '');

class WeeklyReportPage extends StatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  final _store = TransactionStore.instance;
  final DateTime _today = dateOnly(DateTime.now());
  late DateTime _weekStart = weekStartOf(DateTime.now());
  bool _profitMode = false; // false = grafik penjualan, true = grafik profit
  int? _selected; // hari yang disorot di grafik; null = hari terbaik

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

  bool get _isCurrentWeek => _weekStart == weekStartOf(_today);

  void _goToWeek(DateTime start) {
    setState(() {
      _weekStart = start;
      _selected = null;
    });
  }

  void _shiftWeek(int weeks) => _goToWeek(
      DateTime(_weekStart.year, _weekStart.month, _weekStart.day + 7 * weeks));

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart.isAfter(_today) ? _today : _weekStart,
      firstDate: DateTime(2020),
      lastDate: _today,
      helpText: 'Pilih tanggal di minggu yang diinginkan',
    );
    if (picked != null) _goToWeek(weekStartOf(picked));
  }

  void _showDetail(WeekReport r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DetailSheet(report: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = buildWeekReport(_store.items, _weekStart);
    final selected = _selected ?? r.bestDayIndex;
    final change = r.changePct;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient:
                  LinearGradient(colors: [AppColors.orange, AppColors.yellow]),
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Laporan Profit Mingguan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18)),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onSelected: (v) {
                        if (v == 'now') _goToWeek(weekStartOf(_today));
                        if (v == 'export') {
                          showSnack(context,
                              'Ekspor laporan akan tersedia di versi berikutnya.');
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'now',
                          child: Text('Ke minggu ini'),
                        ),
                        PopupMenuItem(
                          value: 'export',
                          child: Text('Ekspor laporan'),
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                // Pilih minggu
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: _pickWeek,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined,
                                    color: AppColors.orange, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${formatDate(r.start, withTime: false)} – '
                                      '${formatDate(r.end, withTime: false)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _RoundArrow(
                        icon: Icons.chevron_left, onTap: () => _shiftWeek(-1)),
                    const SizedBox(width: 8),
                    _RoundArrow(
                      icon: Icons.chevron_right,
                      onTap: _isCurrentWeek ? null : () => _shiftWeek(1),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Kartu profit
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF26B3A), Color(0xFFF9B233)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withAlpha(70),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profit Mingguan',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: r.profit.toDouble()),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (_, v, __) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(formatRupiah(v.round()),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(60),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              change == null
                                  ? Icons.remove
                                  : (change >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down),
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              change == null
                                  ? 'Belum ada pembanding minggu lalu'
                                  : '${change.abs().toStringAsFixed(0)}% '
                                      '${change >= 0 ? 'naik' : 'turun'} dari minggu lalu',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Penjualan & modal
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.payments_outlined,
                        label: 'Total Penjualan',
                        value: r.sales,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.inventory_2_outlined,
                        label: 'Total Modal',
                        value: r.cost,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _MiniInfo(
                            label: 'Transaksi', value: '${r.trxCount}')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _MiniInfo(
                            label: 'Barang terjual', value: '${r.itemsSold}')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _MiniInfo(
                            label: 'Margin',
                            value: '${r.margin.toStringAsFixed(0)}%')),
                  ],
                ),
                if (r.incompleteCost && r.sales > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.amberBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: AppColors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sebagian transaksi tidak punya data harga modal, '
                            'jadi profit bisa terlihat lebih besar dari aslinya.',
                            style: TextStyle(
                                fontSize: 11.5,
                                height: 1.4,
                                color: AppColors.amber),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Tren
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tren Penjualan',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    InkWell(
                      onTap: () => _showDetail(r),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Text('Lihat Detail',
                                style: TextStyle(
                                    color: AppColors.orange,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_circle_right,
                                color: AppColors.orange, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _SegChip(
                            label: 'Penjualan',
                            selected: !_profitMode,
                            onTap: () => setState(() => _profitMode = false),
                          ),
                          const SizedBox(width: 8),
                          _SegChip(
                            label: 'Profit',
                            selected: _profitMode,
                            onTap: () => setState(() => _profitMode = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _TrendChart(
                        days: r.days,
                        profitMode: _profitMode,
                        selected: selected,
                        onSelect: (i) => setState(() => _selected = i),
                      ),
                      const SizedBox(height: 12),
                      _DayInfo(day: r.days[selected], index: selected),
                    ],
                  ),
                ),

                if (r.top.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Produk Terlaris',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 12),
                  for (var i = 0; i < r.top.length; i++)
                    _TopTile(rank: i + 1, item: r.top[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- Komponen ----------
class _RoundArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? const Color(0xFFE5DFC9) : AppColors.orange,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: AppColors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(end: value.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (_, v, __) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(formatRupiah(v.round()),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  const _MiniInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 10.5)),
          ),
        ],
      ),
    );
  }
}

class _SegChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orange : AppColors.card,
      animationDuration: const Duration(milliseconds: 200),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.orange,
              )),
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<DayStat> days;
  final bool profitMode;
  final int selected;
  final ValueChanged<int> onSelect;

  const _TrendChart({
    required this.days,
    required this.profitMode,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const chartH = 150.0;
    final values =
        days.map((d) => max(0, profitMode ? d.profit : d.sales)).toList();
    final maxV = values.fold<int>(0, max);

    return SizedBox(
      height: chartH + 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 18,
                      child: i == selected
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(_compact(values[i]),
                                  style: const TextStyle(
                                      color: AppColors.orange,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800)),
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                      width: 22,
                      height: maxV == 0
                          ? 4
                          : max(4.0, chartH * values[i] / maxV),
                      decoration: BoxDecoration(
                        color: i == selected
                            ? AppColors.orange
                            : AppColors.orange.withAlpha(105),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7)),
                      ),
                    ),
                    Container(
                        height: 1.5,
                        width: double.infinity,
                        color: const Color(0xFFF1E7C8)),
                    const SizedBox(height: 8),
                    Text(_dayShort[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              i == selected ? FontWeight.w800 : FontWeight.w500,
                          color: i == selected
                              ? AppColors.orange
                              : AppColors.muted,
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayInfo extends StatelessWidget {
  final DayStat day;
  final int index;
  const _DayInfo({required this.day, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '${_dayNames[index]}, ${formatDate(day.day, withTime: false)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 12.5)),
              Text('${day.trx} transaksi',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kv('Penjualan', formatRupiah(day.sales)),
              _kv('Profit', formatRupiah(day.profit), color: AppColors.ok),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {Color? color}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          Text(v,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14, color: color)),
        ],
      );
}

class _TopTile extends StatelessWidget {
  final int rank;
  final TopItem item;
  const _TopTile({required this.rank, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1 ? AppColors.orange : AppColors.card,
              shape: BoxShape.circle,
            ),
            child: Text('$rank',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: rank == 1 ? Colors.white : AppColors.orange)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text('${item.qty} terjual • ${formatRupiah(item.sales)}',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11.5)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Profit',
                  style: TextStyle(color: AppColors.muted, fontSize: 10.5)),
              Text(formatRupiah(item.profit),
                  style: const TextStyle(
                      color: AppColors.ok,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final WeekReport report;
  const _DetailSheet({required this.report});

  Widget _cell(String text,
      {int flex = 3,
      bool bold = false,
      Color? color,
      Alignment align = Alignment.centerRight}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: align,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  color: color ?? AppColors.ink)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = report;

    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
            const Text('Rincian per Hari',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(
                '${formatDate(r.start, withTime: false)} – ${formatDate(r.end, withTime: false)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _cell('Hari', flex: 3, bold: true, align: Alignment.centerLeft),
                  _cell('Trx', flex: 2, bold: true),
                  _cell('Penjualan', bold: true),
                  _cell('Modal', bold: true),
                  _cell('Profit', bold: true),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < r.days.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 11, horizontal: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Color(0xFFF5EDD2))),
                      ),
                      child: Row(
                        children: [
                          _cell('${_dayShort[i]} ${r.days[i].day.day}',
                              flex: 3,
                              align: Alignment.centerLeft,
                              bold: true),
                          _cell('${r.days[i].trx}', flex: 2),
                          _cell(_num(r.days[i].sales)),
                          _cell(_num(r.days[i].cost)),
                          _cell(_num(r.days[i].profit), color: AppColors.ok),
                        ],
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _cell('Total',
                            flex: 3, align: Alignment.centerLeft, bold: true),
                        _cell('${r.trxCount}', flex: 2, bold: true),
                        _cell(_num(r.sales), bold: true),
                        _cell(_num(r.cost), bold: true),
                        _cell(_num(r.profit), bold: true, color: AppColors.ok),
                      ],
                    ),
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
