import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/cosmic_theme.dart';

class YogaPanel extends StatelessWidget {
  final List<Yoga> yogas;
  const YogaPanel({super.key, required this.yogas});

  Color _yogaTypeColor(String type) {
    switch (type) {
      case 'raja': return CosmicTheme.starGold;
      case 'dhana': return CosmicTheme.venusGreen;
      case 'pancha_mahapurusha': return CosmicTheme.jupiterOrange;
      case 'chandra': return Colors.white;
      case 'solar': return CosmicTheme.starGold;
      case 'neecha_bhanga': return CosmicTheme.celestialBlue;
      case 'parivartana': return CosmicTheme.ketuBrown;
      case 'daridra': case 'arishta': return CosmicTheme.marsRed;
      default: return CosmicTheme.moonSilver;
    }
  }

  String _yogaTypeLabel(String type) {
    switch (type) {
      case 'raja': return 'Raja Yoga';
      case 'dhana': return 'Dhana Yoga';
      case 'pancha_mahapurusha': return 'Pancha Mahapurusha';
      case 'chandra': return 'Chandra Yoga';
      case 'solar': return 'Solar Yoga';
      case 'neecha_bhanga': return 'Neecha Bhanga';
      case 'parivartana': return 'Parivartana';
      case 'daridra': return 'Daridra Yoga';
      case 'arishta': return 'Arishta Yoga';
      default: return type.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (yogas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: CosmicTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CosmicTheme.borderGlow),
        ),
        child: Column(children: [
          Icon(Icons.search_off, size: 40, color: CosmicTheme.rahuSmoke),
          const SizedBox(height: 12),
          const Text('No prominent yogas detected', style: TextStyle(color: CosmicTheme.rahuSmoke)),
          const SizedBox(height: 4),
          Text('Subtle yogas may require deeper AI analysis.',
            style: TextStyle(color: CosmicTheme.rahuSmoke.withOpacity(0.6), fontSize: 12)),
        ]),
      );
    }

    // Group yogas by type
    final grouped = <String, List<Yoga>>{};
    for (final y in yogas) {
      grouped.putIfAbsent(y.yogaType, () => []).add(y);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Detected Yogas', style: TextStyle(color: CosmicTheme.starGold, fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CosmicTheme.starGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${yogas.length} found', style: const TextStyle(color: CosmicTheme.starGold, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),

        ...yogas.map((y) {
          final color = _yogaTypeColor(y.yogaType);
          final strengthPercent = (y.strength * 100).toInt();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: CosmicTheme.cardGradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_yogaTypeLabel(y.yogaType),
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  // Strength indicator
                  Row(children: [
                    ...List.generate(5, (i) => Container(
                      width: 6, height: 6, margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < (y.strength * 5).ceil() ? color : CosmicTheme.surfaceDark,
                      ),
                    )),
                    const SizedBox(width: 6),
                    Text('$strengthPercent%', style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 10)),
                  ]),
                ]),
                const SizedBox(height: 8),
                Text(y.yogaName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6),
                if (y.description.isNotEmpty)
                  Text(y.description,
                    style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.7), fontSize: 12, height: 1.4)),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.group, size: 12, color: CosmicTheme.rahuSmoke),
                  const SizedBox(width: 4),
                  Text('Planets: ${y.formingPlanets.map((p) => p[0].toUpperCase() + p.substring(1)).join(", ")}',
                    style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 11)),
                  if (y.sourceTradition != null) ...[
                    const Spacer(),
                    Text(y.sourceTradition!, style: TextStyle(color: CosmicTheme.rahuSmoke.withOpacity(0.5), fontSize: 10, fontStyle: FontStyle.italic)),
                  ],
                ]),
              ],
            ),
          );
        }),
      ],
    );
  }
}
