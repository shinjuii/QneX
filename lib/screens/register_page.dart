import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../data/session_store.dart';
import '../widgets/auth_widgets.dart';

/// ---------- Halaman Daftar ----------
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _business = TextEditingController();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agree = false;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _business.dispose();
    _identifier.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      showSnack(context, 'Centang persetujuan Syarat & Ketentuan dulu ya.');
      return;
    }

    setState(() => _loading = true);
    // TODO: ganti dengan proses pendaftaran ke backend/database.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loading = false);
    SessionStore.instance.register(
      name: _name.text.trim(),
      businessName: _business.text.trim(),
      identifier: _identifier.text.trim(),
    );
    Navigator.of(context).pop(true); // kembali ke Login + pesan sukses
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: authBackground,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back),
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                            const Expanded(child: Center(child: BrandWord())),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Buat Akun Baru',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        const Text('Daftarkan usahamu dan mulai kelola dengan QNEX',
                            style:
                                TextStyle(color: AppColors.muted, fontSize: 13)),
                        const SizedBox(height: 14),
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
                                  'Akun yang dibuat di sini adalah akun Owner. '
                                  'Akun karyawan ditambahkan oleh Owner lewat menu Kelola Karyawan.',
                                  style: TextStyle(fontSize: 11.5, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        AuthField(
                          controller: _name,
                          hint: 'Nama lengkap',
                          icon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v ?? '').trim().length < 3
                              ? 'Nama minimal 3 karakter'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        AuthField(
                          controller: _business,
                          hint: 'Nama usaha',
                          icon: Icons.storefront_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Nama usaha wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        AuthField(
                          controller: _identifier,
                          hint: 'Email atau nomor HP',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: validateIdentifier,
                        ),
                        const SizedBox(height: 14),
                        AuthField(
                          controller: _password,
                          hint: 'Kata sandi',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          textInputAction: TextInputAction.next,
                          validator: validatePassword,
                          onChanged: (_) => setState(() {}),
                        ),
                        StrengthBar(password: _password.text),
                        const SizedBox(height: 14),
                        AuthField(
                          controller: _confirm,
                          hint: 'Ulangi kata sandi',
                          icon: Icons.lock_reset_outlined,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            if ((v ?? '').isEmpty) {
                              return 'Ulangi kata sandi terlebih dahulu';
                            }
                            return v == _password.text
                                ? null
                                : 'Kata sandi tidak sama';
                          },
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () => setState(() => _agree = !_agree),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _agree,
                                activeColor: AppColors.orange,
                                onChanged: (v) =>
                                    setState(() => _agree = v ?? false),
                              ),
                              const Expanded(
                                child: Text(
                                  'Saya setuju dengan Syarat & Ketentuan dan Kebijakan Privasi',
                                  style: TextStyle(fontSize: 12, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        GradientButton(
                            label: 'Daftar', loading: _loading, onPressed: _submit),
                        const Spacer(),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Sudah punya akun? ',
                                style: TextStyle(fontSize: 13)),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: AppColors.orange,
                              ),
                              child: const Text('Masuk',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ],
                    ),
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
