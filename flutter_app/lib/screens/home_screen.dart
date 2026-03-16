import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/kundali_provider.dart';
import '../theme/cosmic_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<KundaliProvider>().loadKundaliList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: CosmicTheme.cosmicGradient),
        child: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [_HomeTab(), _ExploreTab()],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: CosmicTheme.cosmicNavy,
          border: Border(top: BorderSide(color: CosmicTheme.borderGlow.withOpacity(0.5))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Explore'),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kundali = context.watch<KundaliProvider>();
    final name = auth.user?.displayName ?? 'Seeker';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Namaste, $name', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('What cosmic wisdom do you seek today?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CosmicTheme.rahuSmoke)),
                ]),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: CosmicTheme.starGold, width: 2),
                  ),
                  child: const Icon(Icons.person, color: CosmicTheme.starGold, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Quick Actions Grid
          _SectionTitle(title: 'Quick Actions'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4,
            children: [
              _ActionCard(icon: Icons.add_circle_outline, label: 'New Kundali', color: CosmicTheme.starGold,
                onTap: () => Navigator.pushNamed(context, '/kundali/generate')),
              _ActionCard(icon: Icons.chat_bubble_outline, label: 'AI Consult', color: CosmicTheme.celestialBlue,
                onTap: () => Navigator.pushNamed(context, '/ai/chat')),
              _ActionCard(icon: Icons.menu_book_rounded, label: 'Knowledge', color: CosmicTheme.venusGreen,
                onTap: () => Navigator.pushNamed(context, '/books')),
              _ActionCard(icon: Icons.dashboard_rounded, label: 'Dashboard', color: CosmicTheme.jupiterOrange,
                onTap: () {
                  if (kundali.currentKundali != null) {
                    Navigator.pushNamed(context, '/kundali/dashboard');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generate or select a kundali first')));
                  }
                }),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Kundalis
          _SectionTitle(title: 'Recent Charts'),
          const SizedBox(height: 12),
          if (kundali.isLoading)
            const Center(child: CircularProgressIndicator(color: CosmicTheme.starGold))
          else if (kundali.kundaliList.isEmpty)
            _EmptyState(
              icon: Icons.auto_awesome,
              message: 'No charts yet. Create your first kundali to begin.',
              action: 'Generate Kundali',
              onTap: () => Navigator.pushNamed(context, '/kundali/generate'),
            )
          else
            ...kundali.kundaliList.take(5).map((k) => _KundaliCard(data: k)),
        ],
      ),
    );
  }
}

class _ExploreTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Explore Traditions', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          ...[
            _TraditionCard(name: 'Parashara', desc: 'Classical Vedic system based on Brihat Parasara Hora Shastra', icon: '🕉️'),
            _TraditionCard(name: 'Classical Hora', desc: 'Phaladipika, Saravali, and other interpretive masterworks', icon: '📜'),
            _TraditionCard(name: 'Jaimini', desc: 'Chara karakas and sign-based dasha systems', icon: '🔮'),
            _TraditionCard(name: 'Prasna', desc: 'Horary astrology from Kerala\'s Prasna Marga tradition', icon: '❓'),
            _TraditionCard(name: 'Krishnamurti Paddhati', desc: 'Modern sub-lord precision timing system', icon: '⏰'),
            _TraditionCard(name: 'Nadi', desc: 'Palm-leaf manuscript-based destiny readings', icon: '🌿'),
          ],
        ],
      ),
    );
  }
}

// ── Reusable Widgets ─────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(title, style: Theme.of(context).textTheme.headlineSmall);
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: CosmicTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _KundaliCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _KundaliCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final bd = data['birth_data'] ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CosmicTheme.starGold.withOpacity(0.15),
            ),
            child: const Icon(Icons.auto_awesome, color: CosmicTheme.starGold, size: 20),
          ),
          title: Text(bd['name'] ?? 'Kundali', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text('${data['ascendant_rashi'] ?? ''} Asc · ${bd['place_name'] ?? ''}',
            style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.7), fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: CosmicTheme.rahuSmoke),
          onTap: () async {
            final provider = context.read<KundaliProvider>();
            await provider.loadKundali(data['id']);
            if (context.mounted) Navigator.pushNamed(context, '/kundali/dashboard');
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String message; final String action; final VoidCallback onTap;
  const _EmptyState({required this.icon, required this.message, required this.action, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CosmicTheme.borderGlow),
      ),
      child: Column(children: [
        Icon(icon, size: 48, color: CosmicTheme.rahuSmoke),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onTap, child: Text(action)),
      ]),
    );
  }
}

class _TraditionCard extends StatelessWidget {
  final String name, desc, icon;
  const _TraditionCard({required this.name, required this.desc, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 28)),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(desc, style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.7), fontSize: 12)),
      ),
    );
  }
}
