import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../data/cart_controller.dart';
import '../data/product_store.dart';
import '../data/transaction_store.dart';
import '../models/transaction.dart';
import '../widgets/auth_widgets.dart';
import 'payment_success_page.dart';
import 'qris_payment_page.dart';

enum PayMethod { cash, qris }

class PaymentPage extends StatefulWidget {
  final CartController cart;
  const PaymentPage({super.key, required this.cart});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _trx = TransactionStore.instance;
  final _products = ProductStore.instance;
  final _cashCtrl = TextEditingController();
  PayMethod _method = PayMethod.cash;

  int get _total => widget.cart.total;
  int get _cash => int.tryParse(_cashCtrl.text) ?? 0;

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  List<int> get _suggestions {
    int up(int v, int step) => ((v + step - 1) ~/ step) * step;
    final set = <int>{
      _total,
      up(_total, 5000),
      up(_total, 10000),
      up(_total, 50000),
      up(_total, 100000),
    };
    final list = set.toList()..sort();
    return list.take(4).toList();
  }

  List<TrxLine> get _trxLines => widget.cart.lines
      .map((l) => TrxLine(l.product.name, l.qty, l.product.price))
      .toList();

  void _payCash() {
    if (_cash < _total) return;
    _finish(method: 'Tunai', cash: _cash);
  }

  Future<void> _payQris() async {
    final orderId = _trx.nextId();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QrisPaymentPage(orderId: orderId, amount: _total),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      _finish(method: 'QRIS', orderId: orderId);
    } else if (result == false) {
      // QR kedaluwarsa: dicatat sebagai transaksi gagal, stok tidak berubah.
      _trx.add(TrxItem(orderId, _total, 'QRIS', DateTime.now(),
          TrxStatus.gagal, lines: _trxLines));
      showSnack(context, 'QR kedaluwarsa. Transaksi dicatat sebagai gagal.');
    }
    // result == null: kasir membatalkan, tidak ada yang dicatat.
  }

  void _finish({required String method, int? cash, String? orderId}) {
    final id = orderId ?? _trx.nextId();
    final item = TrxItem(id, _total, method, DateTime.now(), TrxStatus.berhasil,
        lines: _trxLines, cashReceived: cash);

    _products.sell(widget.cart.lines, id); // kurangi stok
    _trx.add(item); // masuk riwayat transaksi
    widget.cart.clear();

    Navigator.pushReplacement(context, fadeRoute(PaymentSuccessPage(trx: item)));
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.cart.lines;
    final isCash = _method == PayMethod.cash;
    final short = isCash && _cash < _total;

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
        title: const Text('Pembayaran',
            style: TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Opacity(
            opacity: short ? 0.5 : 1,
            child: IgnorePointer(
              ignoring: short,
              child: GradientButton(
                label: isCash ? 'Konfirmasi Pembayaran' : 'Tampilkan QR',
                onPressed: isCash ? _payCash : _payQris,
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // Ringkasan pesanan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ringkasan Pesanan',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 10),
                for (final l in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text(
                                  '${l.qty} × ${formatRupiah(l.product.price)}',
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 11.5)),
                            ],
                          ),
                        ),
                        Text(formatRupiah(l.subtotal),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFF1E7C8)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Bayar',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(formatRupiah(_total),
                        style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 22)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Metode Pembayaran',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          const SizedBox(height: 10),
          _MethodTile(
            icon: Icons.payments_outlined,
            title: 'Tunai',
            subtitle: 'Terima uang dari pelanggan',
            selected: isCash,
            onTap: () => setState(() => _method = PayMethod.cash),
          ),
          const SizedBox(height: 10),
          _MethodTile(
            icon: Icons.qr_code_2,
            title: 'QRIS',
            subtitle: 'Scan dengan e-wallet atau m-banking',
            selected: !isCash,
            onTap: () => setState(() => _method = PayMethod.qris),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: isCash
                ? _cashSection()
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _cashSection() {
    final enough = _cash >= _total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('Uang diterima',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
        const SizedBox(height: 10),
        TextField(
          controller: _cashCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            hintText: '0',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _suggestions
              .map((v) => ActionChip(
                    label: Text(v == _total ? 'Uang pas' : formatRupiah(v)),
                    labelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.line),
                    onPressed: () => setState(() => _cashCtrl.text = '$v'),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: enough ? AppColors.okBg : AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kembalian',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              Text(enough ? formatRupiah(_cash - _total) : '-',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: enough ? AppColors.ok : AppColors.muted)),
            ],
          ),
        ),
        if (_cash > 0 && !enough)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Uang kurang ${formatRupiah(_total - _cash)}',
                style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? AppColors.orange : AppColors.line,
                width: selected ? 1.8 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11.5)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.orange : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
