import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/helpers.dart';
import '../data/session_store.dart';
import '../widgets/logout.dart';
import '../widgets/photo_picker.dart';
import '../widgets/qnex_bottom_bar.dart';
import 'business_settings_page.dart';
import 'help_page.dart';
import 'kasir_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _session = SessionStore.instance;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _changePhoto() async {
    final bytes = await pickProductPhoto(context, title: 'Foto Profil');
    if (bytes != null && mounted) {
      _session.setPhoto(bytes);
      showSnack(context, 'Foto profil diperbarui');
    }
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _about() {
    showAboutDialog(
      context: context,
      applicationName: 'QNEX',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 QNEX',
      children: const [
        SizedBox(height: 12),
        Text('Aplikasi kasir dan manajemen inventori untuk UMKM.',
            style: TextStyle(fontSize: 13, height: 1.4)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _session.current;

    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButtonLocation: QnexCartFab.location,
      floatingActionButton: const QnexCartFab(),
      bottomNavigationBar: QnexBottomBar(
        currentIndex: 4,
        onTap: (i) => qnexGoTo(context, i),
      ),
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient:
                  LinearGradient(colors: [AppColors.orange, AppColors.yellow]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: const SafeArea(
              bottom: false,
              child: SizedBox(
                height: 60,
                child: Center(
                  child: Text('Pengaturan',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
              children: [
                // Profil
                Row(
                  children: [
                    _Avatar(user: user, onTap: _changePhoto),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 20)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withAlpha(60),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(user.roleLabel,
                                style: const TextStyle(
                                    color: Color(0xFF8A5A00),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ),
                          const SizedBox(height: 6),
                          Text(_session.business.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Peran
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RolePill(
                      label: 'Owner',
                      icon: Icons.verified_user_outlined,
                      selected: user.isOwner,
                    ),
                    _RolePill(
                      label: 'Kasir',
                      icon: Icons.point_of_sale,
                      selected: !user.isOwner,
                      onTap: () => _push(const KasirPage()),
                    ),
                    if (user.isOwner)
                      _RolePill(
                        label: 'Kelola Pengguna',
                        icon: Icons.group_outlined,
                        selected: false,
                        onTap: () => showSnack(context,
                            'Kelola Pengguna akan hadir di versi berikutnya.'),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFF1E7C8)),
                const SizedBox(height: 18),

                // Menu
                if (user.isOwner)
                  _MenuTile(
                    icon: Icons.storefront_outlined,
                    title: 'Pengaturan usaha',
                    subtitle: 'Nama usaha, alamat, catatan struk',
                    onTap: () => _push(const BusinessSettingsPage()),
                  ),
                _MenuTile(
                  icon: Icons.help_outline,
                  title: 'Bantuan & Panduan',
                  subtitle: 'Cara memakai QNEX',
                  onTap: () => _push(const HelpPage()),
                ),
                _MenuTile(
                  icon: Icons.info_outline,
                  title: 'Tentang QNEX',
                  subtitle: 'Versi 1.0.0',
                  onTap: _about,
                ),
                const SizedBox(height: 22),

                // Keluar
                Center(
                  child: SizedBox(
                    width: 220,
                    child: OutlinedButton.icon(
                      onPressed: () => confirmAndLogout(context),
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Keluar',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(
                            color: AppColors.danger, width: 1.5),
                        minimumSize: const Size(0, 50),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Center(
                  child: Text('QNEX v1.0.0',
                      style: TextStyle(color: AppColors.muted, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- Komponen ----------
class _Avatar extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;
  const _Avatar({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.orange, AppColors.yellow],
            ),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: user.photo != null
                ? Image.memory(user.photo!,
                    width: 92, height: 92, fit: BoxFit.cover, gaplessPlayback: true)
                : Center(
                    child: Text(user.initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 38)),
                  ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: AppColors.orange,
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 2),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const SizedBox(
                width: 30,
                height: 30,
                child: Icon(Icons.camera_alt, size: 15, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _RolePill({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.orange;
    return Material(
      color: selected ? AppColors.orange : Colors.white,
      animationDuration: const Duration(milliseconds: 200),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.orange : AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: fg, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.orange, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11.5)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
