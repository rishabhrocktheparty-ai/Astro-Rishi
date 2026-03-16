import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/kundali_provider.dart';
import '../models/models.dart';
import '../theme/cosmic_theme.dart';
import '../widgets/south_indian_chart.dart';
import '../widgets/planet_table.dart';
import '../widgets/dasha_timeline.dart';
import '../widgets/yoga_panel.dart';

class KundaliDashboardScreen extends StatefulWidget {
  const KundaliDashboardScreen({super.key});
  @override
  State<KundaliDashboardScreen> createState() => _KundaliDashboardScreenState();
}

class _KundaliDashboardScreenState extends State<KundaliDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final kundali = context.watch<KundaliProvider>().currentKundali;

    if (kundali == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kundali Dashboard')),
        body: const Center(child: Text('No kundali loaded', style: TextStyle(color: CosmicTheme.moonSilver))),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(kundali.name ?? 'Kundali'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 22),
            tooltip: 'AI Consult',
            onPressed: () => Navigator.pushNamed(context, '/ai/chat'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: CosmicTheme.cosmicGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Ascendant Summary Header
              _AscendantHeader(kundali: kundali),
              const SizedBox(height: 4),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: CosmicTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: CosmicTheme.starGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: CosmicTheme.starGold,
                  unselectedLabelColor: CosmicTheme.rahuSmoke,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Chart'),
                    Tab(text: 'Planets'),
                    Tab(text: 'Yogas'),
                    Tab(text: 'Dasha'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ChartTab(kundali: kundali),
                    _PlanetsTab(kundali: kundali),
                    _YogasTab(kundali: kundali),
                    _DashaTab(kundali: kundali),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ascendant Summary Header ─────────────────────────────
class _AscendantHeader extends StatelessWidget {
  final Kundali kundali;
  const _AscendantHeader({required this.kundali});

  @override
  Widget build(BuildContext context) {
    final currentMaha = kundali.currentMahaDasha;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CosmicTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CosmicTheme.starGold.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // Ascendant icon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: CosmicTheme.goldGradient,
              boxShadow: [BoxShadow(color: CosmicTheme.starGold.withOpacity(0.3), blurRadius: 12)],
            ),
            child: Center(child: Text(
              kundali.ascendantRashi.isNotEmpty ? kundali.ascendantRashi.substring(0, 2) : '?',
              style: const TextStyle(color: CosmicTheme.deepSpace, fontWeight: FontWeight.w900, fontSize: 18),
            )),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${kundali.ascendantRashi} Ascendant',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 2),
            Text('${kundali.ascendantNakshatra} Pada ${kundali.ascendantPada}',
              style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.7), fontSize: 12)),
          ])),
          if (currentMaha != null) ...[
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Current Dasha', style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 10)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CosmicTheme.getPlanetColor(currentMaha.planet).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CosmicTheme.getPlanetColor(currentMaha.planet).withOpacity(0.4)),
                ),
                child: Text(
                  currentMaha.planet.toUpperCase(),
                  style: TextStyle(color: CosmicTheme.getPlanetColor(currentMaha.planet), fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ── Chart Tab ────────────────────────────────────────────
class _ChartTab extends StatelessWidget {
  final Kundali kundali;
  const _ChartTab({required this.kundali});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // South Indian Chart
        SouthIndianChart(kundali: kundali),
        const SizedBox(height: 20),

        // Quick planet overview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: CosmicTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CosmicTheme.borderGlow),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Planet Overview', style: TextStyle(color: CosmicTheme.starGold, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: kundali.planets.values.map((p) => _PlanetChip(planet: p)).toList(),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _PlanetChip extends StatelessWidget {
  final PlanetPosition planet;
  const _PlanetChip({required this.planet});

  @override
  Widget build(BuildContext context) {
    final color = CosmicTheme.getPlanetColor(planet.planet);
    final dignityIcon = planet.dignity == 'exalted' ? '↑'
        : planet.dignity == 'debilitated' ? '↓'
        : planet.dignity == 'own' ? '⌂'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(
          '${planet.planet[0].toUpperCase()}${planet.planet.substring(1)} ${planet.rashi.substring(0, 3)} H${planet.houseNumber} $dignityIcon',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        if (planet.isRetrograde) ...[
          const SizedBox(width: 4),
          Text('R', style: TextStyle(color: CosmicTheme.marsRed, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ]),
    );
  }
}

// ── Planets Tab ──────────────────────────────────────────
class _PlanetsTab extends StatelessWidget {
  final Kundali kundali;
  const _PlanetsTab({required this.kundali});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: PlanetTable(planets: kundali.planets.values.toList()),
    );
  }
}

// ── Yogas Tab ────────────────────────────────────────────
class _YogasTab extends StatelessWidget {
  final Kundali kundali;
  const _YogasTab({required this.kundali});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: YogaPanel(yogas: kundali.yogas),
    );
  }
}

// ── Dasha Tab ────────────────────────────────────────────
class _DashaTab extends StatelessWidget {
  final Kundali kundali;
  const _DashaTab({required this.kundali});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DashaTimeline(dashas: kundali.mahaDashas),
    );
  }
}
