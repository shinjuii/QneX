import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../widgets/auth_illustration.dart';
import '../widgets/auth_widgets.dart';
import 'owner_dashboard_page.dart';
import 'register_page.dart';

/// ---------- Halaman Login ----------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _loading = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;

    setState(() => _loading = true);
    // TODO: ganti dengan proses login ke backend/database.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loading = false);

    // TODO: arahkan sesuai peran: owner -> dashboard owner,
    // karyawan -> halaman kasir. Sementara semua ke dashboard owner.
    Navigator.of(
      context,
    ).pushReplacement(fadeRoute(const OwnerDashboardPage()));
  }

  Future<void> _openRegister() async {
    final registered = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const RegisterPage()));
    if (registered == true && mounted) {
      showSnack(context, 'Akun berhasil dibuat. Silakan masuk.');
    }
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
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Form(
                    key: _form,
                    child: Column(
                      children: [
                        const BrandWord(),
                        const SizedBox(height: 14),
                        const Text(
                          'Selamat Datang!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Masuk ke akun Anda untuk melanjutkan',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const AuthIllustration(),
                        const SizedBox(height: 8),
                        AuthField(
                          controller: _identifier,
                          hint: 'Email atau nomor HP',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: validateIdentifier,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 14),
                        AuthField(
                          controller: _password,
                          focusNode: _passwordFocus,
                          hint: 'Kata sandi',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          validator: validatePassword,
                          onSubmitted: (_) => _submit(),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => showSnack(
                              context,
                              'Fitur lupa kata sandi aktif setelah server terhubung.',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.orange,
                            ),
                            child: const Text(
                              'Lupa kata sandi?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GradientButton(
                          label: 'Masuk',
                          loading: _loading,
                          onPressed: _submit,
                        ),
                        const Spacer(),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Belum punya akun? ',
                              style: TextStyle(fontSize: 13),
                            ),
                            TextButton(
                              onPressed: _openRegister,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: AppColors.orange,
                              ),
                              child: const Text(
                                'Daftar',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
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
