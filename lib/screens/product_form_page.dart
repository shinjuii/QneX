import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../data/product_store.dart';
import '../models/product.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/photo_picker.dart';

/// Dipakai untuk dua hal: tambah produk baru (product == null)
/// atau edit produk yang sudah ada.
class ProductFormPage extends StatefulWidget {
  final Product? product;
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _form = GlobalKey<FormState>();
  final _store = ProductStore.instance;

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _cost;
  late final TextEditingController _stock;
  late final TextEditingController _min;
  late final TextEditingController _cap;
  late final TextEditingController _location;

  late String _category;
  late String _unit;
  late DateTime _entry;
  DateTime? _expiry;
  Uint8List? _photo;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p == null ? '' : '${p.price}');
    _cost = TextEditingController(text: p == null ? '' : '${p.costPrice}');
    _stock = TextEditingController(text: '');
    _min = TextEditingController(text: p == null ? '10' : '${p.minStock}');
    _cap = TextEditingController(text: p == null ? '100' : '${p.capacity}');
    _location = TextEditingController(text: p?.location ?? '');
    _category = p?.category ?? kCategories.first;
    _unit = p?.unit ?? kUnits.first;
    _entry = p?.entryDate ?? dateOnly(DateTime.now());
    _expiry = p?.expiry;
    _photo = p?.photo;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _cost.dispose();
    _stock.dispose();
    _min.dispose();
    _cap.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final bytes = await pickProductPhoto(context);
    if (bytes != null && mounted) setState(() => _photo = bytes);
  }

  Future<void> _pickDate({required bool expiry}) async {
    final initial = expiry ? (_expiry ?? DateTime.now()) : _entry;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (expiry) {
        _expiry = dateOnly(picked);
      } else {
        _entry = dateOnly(picked);
      }
    });
  }

  String? _needNumber(String? v, String msg, {int min = 0}) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < min) return msg;
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;

    final name = _name.text.trim();
    final price = int.parse(_price.text.trim());
    final cost = int.parse(_cost.text.trim());
    final min = int.parse(_min.text.trim());
    final cap = int.parse(_cap.text.trim());
    final location = _location.text.trim();

    if (_isEdit) {
      final p = widget.product!;
      final categoryChanged = p.category != _category;
      p
        ..name = name
        ..category = _category
        ..unit = _unit
        ..price = price
        ..costPrice = cost
        ..minStock = min
        ..capacity = cap
        ..entryDate = _entry
        ..expiry = _expiry
        ..location = location
        ..photo = _photo;
      if (categoryChanged) p.icon = iconForCategory(_category);
      _store.update();
      if (!mounted) return;
      showSnack(context, 'Perubahan produk disimpan');
    } else {
      final stock = int.parse(_stock.text.trim());
      await _store.add(Product(
        id: _store.newId(),
        name: name,
        category: _category,
        unit: _unit,
        price: price,
        costPrice: cost,
        stock: stock,
        minStock: min,
        capacity: cap,
        entryDate: _entry,
        expiry: _expiry,
        location: location,
        photo: _photo,
        icon: iconForCategory(_category),
        history: stock > 0 ? [StockLog(_entry, stock, 'Stok awal')] : [],
      ));
      if (!mounted) return;
      showSnack(context, '$name ditambahkan ke inventori');
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: AppColors.cream,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.ink),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk',
            style: const TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  Material(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _pickPhoto,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border:
                          Border.all(color: AppColors.line, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: _photo != null
                              ? Image.memory(_photo!,
                              fit: BoxFit.cover, gaplessPlayback: true)
                              : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: AppColors.orange, size: 30),
                              SizedBox(height: 6),
                              Text('Tambah foto',
                                  style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: Text(_photo == null ? 'Unggah foto' : 'Ganti foto'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.orange),
                      ),
                      if (_photo != null)
                        TextButton(
                          onPressed: () => setState(() => _photo = null),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger),
                          child: const Text('Hapus'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            _LabeledField(
              label: 'Nama produk',
              controller: _name,
              hint: 'Contoh: Indomie Goreng',
              capitalization: TextCapitalization.words,
              validator: (v) => (v ?? '').trim().isEmpty
                  ? 'Nama produk wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),

            const _Label('Kategori'),
            const SizedBox(height: 8),
            _ChipGroup(
              options: kCategories,
              selected: _category,
              onSelected: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),

            const _Label('Satuan'),
            const SizedBox(height: 8),
            _ChipGroup(
              options: kUnits,
              selected: _unit,
              onSelected: (v) => setState(() => _unit = v),
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Harga jual',
                    controller: _price,
                    hint: '0',
                    prefix: 'Rp ',
                    number: true,
                    validator: (v) => _needNumber(v, 'Isi harga jual', min: 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledField(
                    label: 'Harga modal',
                    controller: _cost,
                    hint: '0',
                    prefix: 'Rp ',
                    number: true,
                    validator: (v) => _needNumber(v, 'Isi harga modal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isEdit)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: AppColors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jumlah stok diubah lewat tombol Stok Masuk di halaman '
                            'detail supaya tercatat di riwayat.',
                        style: TextStyle(fontSize: 11.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
            else
              _LabeledField(
                label: 'Stok awal',
                controller: _stock,
                hint: '0',
                number: true,
                suffix: _unit,
                validator: (v) => _needNumber(v, 'Isi stok awal'),
              ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'Stok minimum',
                    controller: _min,
                    hint: '10',
                    number: true,
                    validator: (v) => _needNumber(v, 'Isi stok minimum'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledField(
                    label: 'Kapasitas (stok penuh)',
                    controller: _cap,
                    hint: '100',
                    number: true,
                    validator: (v) {
                      final err = _needNumber(v, 'Isi kapasitas', min: 1);
                      if (err != null) return err;
                      final cap = int.parse(v!.trim());
                      final cur = _isEdit
                          ? widget.product!.stock
                          : (int.tryParse(_stock.text.trim()) ?? 0);
                      final minV = int.tryParse(_min.text.trim()) ?? 0;
                      final need = cur > minV ? cur : minV;
                      return cap < need ? 'Minimal $need' : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Tanggal masuk',
                    value: formatDate(_entry, withTime: false),
                    onTap: () => _pickDate(expiry: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Kedaluwarsa (opsional)',
                    value: _expiry == null
                        ? 'Tidak ada'
                        : formatDate(_expiry!, withTime: false),
                    muted: _expiry == null,
                    onTap: () => _pickDate(expiry: true),
                    onClear: _expiry == null
                        ? null
                        : () => setState(() => _expiry = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _LabeledField(
              label: 'Lokasi stok (opsional)',
              controller: _location,
              hint: 'Contoh: Rak A1',
              capitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 26),

            GradientButton(
              label: _isEdit ? 'Simpan Perubahan' : 'Simpan Produk',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5));
}

OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(14),
  borderSide: BorderSide(color: c, width: w),
);

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? prefix;
  final String? suffix;
  final bool number;
  final TextCapitalization capitalization;
  final String? Function(String?)? validator;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.prefix,
    this.suffix,
    this.number = false,
    this.capitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          textCapitalization: capitalization,
          inputFormatters: number
              ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ]
              : null,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
            prefixText: prefix,
            suffixText: suffix,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: _border(AppColors.line),
            enabledBorder: _border(AppColors.line),
            focusedBorder: _border(AppColors.gold, 1.8),
            errorBorder: _border(AppColors.danger),
            focusedErrorBorder: _border(AppColors.danger, 1.8),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.muted = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 50,
              padding: const EdgeInsets.only(left: 14, right: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: muted ? AppColors.muted : AppColors.ink,
                        )),
                  ),
                  if (onClear != null)
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close,
                          size: 18, color: AppColors.muted),
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.calendar_today_outlined,
                          size: 18, color: AppColors.orange),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final on = o == selected;
        return ChoiceChip(
          label: Text(o),
          selected: on,
          showCheckmark: false,
          selectedColor: AppColors.orange,
          backgroundColor: Colors.white,
          side: BorderSide(color: on ? AppColors.orange : AppColors.line),
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: on ? Colors.white : AppColors.ink,
          ),
          onSelected: (_) => onSelected(o),
        );
      }).toList(),
    );
  }
}