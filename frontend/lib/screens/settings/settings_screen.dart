import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/custom_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editApiUrl(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final controller = TextEditingController(text: settings.apiBaseUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alamat server API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alamat API backend. Perubahan ini disimpan di perangkat.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Base URL API',
                hintText: 'http://10.0.2.2/autolog/api',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || !context.mounted) return;
    final saved = await settings.setApiBaseUrl(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved
            ? 'Alamat server berhasil disimpan.'
            : settings.errorMessage ?? 'Gagal menyimpan alamat server.'),
      ),
    );
  }

  Future<void> _resetApiUrl(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final reset = await settings.resetApiBaseUrl();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reset
            ? 'Alamat server dikembalikan ke bawaan.'
            : settings.errorMessage ?? 'Gagal mereset alamat server.'),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final isGuest = auth.isGuest;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isGuest ? 'Keluar dari mode tamu?' : 'Keluar akun?'),
        content: Text(
          isGuest
              ? 'Data lokal tetap tersimpan dan bisa dibuka lagi di perangkat ini.'
              : 'Anda perlu masuk kembali untuk mengakses data akun.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isGuest ? 'Keluar' : 'Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    context.read<VehicleProvider>().reset();
    context.read<ServiceProvider>().reset();
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F8B80).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    (user?.name.isNotEmpty == true
                            ? user!.name.substring(0, 1)
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF0F8B80),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Pengguna AutoLog',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        auth.isGuest
                            ? 'Mode tamu • Data tersimpan di perangkat'
                            : user?.email ?? '',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  auth.isGuest
                      ? Icons.phone_android_rounded
                      : Icons.verified_user_outlined,
                  color: const Color(0xFF0F8B80),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(title: 'Tampilan'),
          const SizedBox(height: 10),
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tema aplikasi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.settings_suggest_outlined),
                      label: Text('Sistem'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Terang'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Gelap'),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) async {
                    final saved = await settings.setThemeMode(selection.single);
                    if (!context.mounted || saved) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            settings.errorMessage ?? 'Gagal menyimpan tema.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  isDark
                      ? 'Tampilan gelap sedang aktif.'
                      : 'Tampilan terang sedang aktif.',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(title: 'Koneksi'),
          const SizedBox(height: 10),
          CustomCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const _LeadingIcon(
                    icon: Icons.dns_outlined,
                    color: Color(0xFF4F6BED),
                  ),
                  title: const Text(
                    'Server API',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    settings.apiBaseUrl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: () => _editApiUrl(context),
                ),
                Divider(
                  height: 1,
                  indent: 66,
                  color: Theme.of(context).dividerColor,
                ),
                ListTile(
                  leading: const _LeadingIcon(
                    icon: Icons.restart_alt_rounded,
                    color: Color(0xFFF2A93B),
                  ),
                  title: const Text('Reset server ke bawaan'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _resetApiUrl(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(title: 'Akun'),
          const SizedBox(height: 10),
          CustomCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: _LeadingIcon(
                icon: Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                auth.isGuest ? 'Keluar dari mode tamu' : 'Logout',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                auth.isGuest
                    ? 'Data lokal tetap tersimpan di perangkat'
                    : 'Keluar dari akun AutoLog ini',
              ),
              onTap: () => _logout(context),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.directions_car_filled_rounded,
                  size: 24,
                  color: Color(0xFF0F8B80),
                ),
                const SizedBox(height: 6),
                Text(
                  'AutoLog',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Kelola kendaraan dengan lebih tenang',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).hintColor,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _LeadingIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
