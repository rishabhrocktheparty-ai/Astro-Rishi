import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/cosmic_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Profile')),
      body: Container(
        decoration: const BoxDecoration(gradient: CosmicTheme.cosmicGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: CosmicTheme.goldGradient,
                    boxShadow: [BoxShadow(color: CosmicTheme.starGold.withOpacity(0.3), blurRadius: 20)],
                  ),
                  child: Center(child: Text(
                    (user?.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: CosmicTheme.deepSpace, fontSize: 32, fontWeight: FontWeight.w900),
                  )),
                ),
                const SizedBox(height: 16),
                Text(user?.displayName ?? 'User', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 13)),
                const SizedBox(height: 32),

                // Settings cards
                _SettingCard(
                  icon: Icons.language, title: 'Language',
                  value: user?.preferredLanguage == 'hi' ? 'Hindi' : user?.preferredLanguage == 'sa' ? 'Sanskrit' : 'English',
                ),
                _SettingCard(
                  icon: Icons.auto_awesome, title: 'Preferred Tradition',
                  value: _tradLabel(user?.preferredTradition ?? 'parashara'),
                ),
                _SettingCard(
                  icon: Icons.access_time, title: 'Timezone',
                  value: user?.timezone ?? 'Asia/Kolkata',
                ),
                if (user?.isAdmin == true)
                  _SettingCard(icon: Icons.admin_panel_settings, title: 'Role', value: 'Administrator'),
                const SizedBox(height: 24),

                // About section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: CosmicTheme.cardGradient,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CosmicTheme.borderGlow),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('About Jyotish AI', style: TextStyle(color: CosmicTheme.starGold, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text(
                        'A self-learning Vedic astrology intelligence system that draws knowledge from classical Sanskrit texts like Brihat Parasara Hora Shastra, Phaladipika, and Prasna Marga.',
                        style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.7), fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Text('Version 1.0.0', style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Links
                _LinkTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy'),
                _LinkTile(icon: Icons.description_outlined, title: 'Terms of Service'),
                _LinkTile(icon: Icons.help_outline, title: 'Help & Support'),
                const SizedBox(height: 24),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) Navigator.pushReplacementNamed(context, '/auth');
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CosmicTheme.marsRed,
                      side: const BorderSide(color: CosmicTheme.marsRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _tradLabel(String slug) {
    const map = {
      'parashara': 'Parashara', 'jaimini': 'Jaimini', 'krishnamurti': 'Krishnamurti Paddhati',
      'classical_hora': 'Classical Hora', 'prasna': 'Prasna (Horary)', 'nadi': 'Nadi',
    };
    return map[slug] ?? slug;
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon; final String title; final String value;
  const _SettingCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: CosmicTheme.starGold, size: 22),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          trailing: Text(value, style: const TextStyle(color: CosmicTheme.moonSilver, fontSize: 13)),
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon; final String title;
  const _LinkTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: CosmicTheme.rahuSmoke, size: 20),
          title: Text(title, style: const TextStyle(color: CosmicTheme.moonSilver, fontSize: 13)),
          trailing: const Icon(Icons.chevron_right, color: CosmicTheme.rahuSmoke, size: 18),
        ),
      ),
    );
  }
}
