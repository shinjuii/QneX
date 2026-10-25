import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../data/session_store.dart';
import '../widgets/auth_widgets.dart';

class BusinessSettingsPage extends StatefulWidget {
  const BusinessSettingsPage({super.key});

  @override
  State<BusinessSettingsPage> createState() => _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends State<BusinessSettingsPage> {
  final _form = GlobalKey<FormState>();
  final _session = SessionStore.instance;

  late final _name = TextEditingController(text: _session.business.name);
  late final _address = TextEditingController(text: _session.business.address);
  late final _phone = TextEditingController(text: _session.business.phone);
  late final _note = TextEditingController(text: _session.business.receiptNote);

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    _session.updateBusiness(
      name: _name.text.trim(),
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      receiptNote: _note.text.trim(),
    );
    showSnack(context, 'Pengaturan usaha disimpan');
    Navigator.pop(context);
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      );

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
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Pengaturan Usaha',
            style: TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 18, color: AppColors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nama usaha dan catatan di sini akan tampil di struk pembelian.',
                      style: TextStyle(fontSize: 11.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _label('Nama usaha'),
            AuthField(
              controller: _name,
              hint: 'Contoh: Warung Kumar',
              icon: Icons.storefront_outlined,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Nama usaha wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            _label('Alamat (opsional)'),
            AuthField(
              controller: _address,
              hint: 'Alamat usaha',
              icon: Icons.location_on_outlined,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            _label('Nomor HP usaha (opsional)'),
            AuthField(
              controller: _phone,
              hint: '08xxxxxxxxxx',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                final digits = t.replaceAll(RegExp(r'[\s\-+]'), '');
                return RegExp(r'^\d{9,14}$').hasMatch(digits)
                    ? null
                    : 'Nomor HP tidak valid';
              },
            ),
            const SizedBox(height: 14),
            _label('Catatan di struk (opsional)'),
            AuthField(
              controller: _note,
              hint: 'Contoh: Terima kasih sudah berbelanja',
              icon: Icons.edit_note,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 26),
            GradientButton(label: 'Simpan', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
