import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../data/transaction_store.dart';
import '../models/transaction.dart';
import '../widgets/receipt_card.dart';
import '../widgets/qnex_bottom_bar.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final _store = TransactionStore.instance;
  List<TrxItem> get _all => _store.items;

  String _query = '';
  TrxStatus? _status; // null = Semua
  String? _method; // null = semua metode

  @override
  void initState() {
    super.initState();
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
            const Text('Metode Pembayaran',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
        title: const Text('Riwayat Transaksi',
            style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
                fontSize: 17)),
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
                          color: AppColors.idGrey, fontSize: 14),
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.navy),
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
                    child: Text('Transaksi tidak ditemukan',
                        style: TextStyle(color: AppColors.idGrey)),
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
      floatingActionButton: const QnexCartFab(),
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

  const _FilterPill(
      {required this.label, required this.selected, required this.onTap});

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
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.ink : AppColors.idGrey,
                )),
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
          onTap: () => _showReceipt(context, item),
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
                      Text('#${item.id}',
                          style: const TextStyle(
                              color: AppColors.idGrey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(formatRupiah(item.amount),
                          style: const TextStyle(
                              color: AppColors.amountGrey,
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${item.method} • ${formatDate(item.time)}',
                          style: const TextStyle(
                              color: AppColors.idGrey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: ok ? AppColors.successBg : AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(ok ? 'Berhasil' : 'Gagal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ok ? AppColors.success : AppColors.danger,
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

void _showReceipt(BuildContext context, TrxItem t) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgSoft,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: ReceiptCard(trx: t),
      ),
    ),
  );
}
