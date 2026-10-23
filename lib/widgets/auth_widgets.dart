import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// ---------- Komponen bersama login & daftar ----------
class BrandWord extends StatelessWidget {
  const BrandWord();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 4),
          child: Text(
            'QNEX',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppColors.gold,
            ),
          ),
        ),
        Positioned(
          right: -10,
          top: -2,
          child: Icon(Icons.north_east, color: AppColors.orange, size: 18),
        ),
      ],
    );
  }
}

class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _hidden = true;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.isPassword && _hidden,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        prefixIcon: Icon(widget.icon, color: AppColors.orange, size: 22),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.muted,
                  size: 22,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: _border(const Color(0xFFF3E3A8)),
        enabledBorder: _border(const Color(0xFFF3E3A8)),
        focusedBorder: _border(AppColors.gold, 1.8),
        errorBorder: _border(AppColors.danger),
        focusedErrorBorder: _border(AppColors.danger, 1.8),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const GradientButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [AppColors.orange, AppColors.yellow],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withAlpha(70),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withAlpha(70),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: loading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        key: const ValueKey('label'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indikator kekuatan kata sandi (muncul saat mengetik di halaman Daftar).
class StrengthBar extends StatelessWidget {
  final String password;
  const StrengthBar({required this.password});

  int get _level {
    if (password.isEmpty) return 0;
    var s = 0;
    if (password.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      s++;
    }
    if (RegExp(r'\d').hasMatch(password)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) s++;
    return s < 1 ? 1 : s;
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    const colors = [
      Colors.transparent,
      AppColors.danger,
      AppColors.orange,
      AppColors.gold,
      Color(0xFF3FA66B),
    ];
    const labels = ['', 'Lemah', 'Sedang', 'Baik', 'Kuat'];

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: level == 0
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  for (var i = 1; i <= 4; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 5,
                        margin: EdgeInsets.only(right: i == 4 ? 0 : 5),
                        decoration: BoxDecoration(
                          color: i <= level
                              ? colors[level]
                              : const Color(0xFFEDE3C2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Text(
                    labels[level],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors[level],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
