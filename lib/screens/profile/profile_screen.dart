import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'edit_profile_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + name
          Center(child: Column(children: [
            Stack(children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                backgroundImage: user?['profile_image'] != null
                    ? NetworkImage(user!['profile_image']) : null,
                child: user?['profile_image'] == null
                    ? Text((user?['name'] ?? 'U')[0],
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 36))
                    : null,
              ),
              Positioned(
                right: 0, bottom: 0,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(user?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 4),
            Text(user?['phone'] ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
            if (user?['city'] != null) ...[
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
                Text(' ${user!['city']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ]),
            ],
          ])),
          const SizedBox(height: 24),

          // Stats row
          Row(children: [
            _StatBox('₹${double.tryParse(user?['total_spent']?.toString() ?? '0')?.toStringAsFixed(0) ?? 0}', 'Spent'),
            const SizedBox(width: 10),
            _StatBox('₹${double.tryParse(user?['wallet_balance']?.toString() ?? '0')?.toStringAsFixed(0) ?? 0}', 'Wallet'),
            const SizedBox(width: 10),
            _StatBox(user?['referral_code'] ?? '–', 'Referral'),
          ]),
          const SizedBox(height: 20),

          // Account section
          const _SectionHeader('My Account'),
          GkmCard(child: Column(children: [
            _Tile(Icons.person_outline, 'Edit Profile', () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
            _divider(),
            _Tile(Icons.account_balance_wallet_outlined, 'Wallet & Payments', () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
            _divider(),
            _Tile(Icons.calendar_today_outlined, 'My Bookings', () =>
                Navigator.pushNamed(context, '/bookings')),
            _divider(),
            _Tile(Icons.subscriptions_outlined, 'My Subscriptions', () =>
                Navigator.pushNamed(context, '/subscriptions')),
            _divider(),
            _Tile(Icons.local_florist_outlined, 'Plant History', () =>
                Navigator.pushNamed(context, '/plant')),
            _divider(),
            _Tile(Icons.warning_amber_outlined, 'My Complaints', () =>
                Navigator.pushNamed(context, '/complaints')),
            _divider(),
            _Tile(Icons.notifications_outlined, 'Notifications', () =>
                Navigator.pushNamed(context, '/notifications')),
          ])),
          const SizedBox(height: 12),

          // Support section
          const _SectionHeader('Support'),
          GkmCard(child: Column(children: [
            _Tile(Icons.location_on_outlined, 'Service Areas', () =>
                Navigator.pushNamed(context, '/service-areas')),
            _divider(),
            _Tile(Icons.help_outline, 'Help & Support', () {}),
            _divider(),
            _Tile(Icons.star_rate_outlined, 'Rate the App', () {}),
            _divider(),
            _Tile(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
            _divider(),
            _Tile(Icons.description_outlined, 'Terms of Service', () {}),
          ])),
          const SizedBox(height: 12),

          // Logout
          GkmCard(child: _Tile(Icons.logout, 'Logout', () async {
            final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
              title: const Text('Logout?'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Logout', style: TextStyle(color: Colors.red))),
              ],
            ));
            if (ok == true && context.mounted) {
              await context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            }
          }, color: Colors.red)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 52);

  Widget _Tile(IconData icon, String label, VoidCallback onTap, {Color? color}) =>
      ListTile(
        leading: Icon(icon, color: color ?? AppTheme.textSecondary, size: 22),
        title: Text(label, style: TextStyle(
            color: color ?? AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: color == null
            ? const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20)
            : null,
        onTap: onTap, dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
  );
}

class _StatBox extends StatelessWidget {
  final String value, label;
  const _StatBox(this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    ]),
  ));
}
