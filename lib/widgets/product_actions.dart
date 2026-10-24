import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../data/product_store.dart';
import '../models/product.dart';
import 'auth_widgets.dart';
import 'product_thumb.dart';

/// Membuka panel "Stok Masuk". Kalau disimpan, stok produk langsung bertambah.
Future<void> showRestockSheet(BuildContext context, Product p) async {
  final added = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => RestockSheet(product: p),
  );
  if (added != null && added > 0 && context.mounted) {
    ProductStore.instance.restock(p, added);
    showSnack(context, 'Stok ${p.name} bertambah $added (sekarang ${p.stock})');
  }
}

/// Dialog konfirmasi hapus. Mengembalikan true kalau owner memilih Hapus.
Future<bool> confirmDeleteProduct(BuildContext context, Product p) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 32),
      title: const Text('Hapus produk?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Text(
        '${p.name} akan dihapus dari inventori beserta riwayat stoknya. '
        'Tindakan ini tidak bisa dibatalkan.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class RestockSheet extends StatefulWidget {
  final Product product;
  const RestockSheet({super.key, required this.product});

  @override
  State<RestockSheet> createState() => _RestockSheetState();
}

class _RestockSheetState extends State<RestockSheet> {
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
          20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
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
              ProductThumb(product: p, size: 44, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('Stok saat ini: ${p.stock} ${p.unit}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Jumlah stok masuk',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
                      fontSize: 22, fontWeight: FontWeight.w800),
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
                      borderSide:
                          const BorderSide(color: AppColors.gold, width: 1.8),
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
                .map((n) => ActionChip(
                      label: Text('+$n'),
                      labelStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.line),
                      onPressed: () => _set(_qty + n),
                    ))
                .toList(),
          ),
          if (_qty == 0)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Masukkan jumlah lebih dari 0',
                  style: TextStyle(color: AppColors.danger, fontSize: 11)),
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
                const Text('Stok setelah diisi',
                    style: TextStyle(fontSize: 12.5)),
                Text('${p.stock}  →  ${p.stock + _qty}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.orange)),
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
