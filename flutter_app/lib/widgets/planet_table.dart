import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/cosmic_theme.dart';

class PlanetTable extends StatelessWidget {
  final List<PlanetPosition> planets;
  const PlanetTable({super.key, required this.planets});

  Widget _dignityBadge(String dignity) {
    Color color;
    String label;
    switch (dignity) {
      case 'exalted':
        color = CosmicTheme.venusGreen; label = 'Exalted';
      case 'own':
        color = CosmicTheme.celestialBlue; label = 'Own';
      case 'moolatrikona':
        color = CosmicTheme.saturnBlue; label = 'M.Tri';
      case 'friend':
        color = CosmicTheme.jupiterOrange; label = 'Friend';
      case 'enemy':
        color = CosmicTheme.marsRed; label = 'Enemy';
      case 'debilitated':
        color = CosmicTheme.marsRed; label = 'Debil.';
      default:
        color = CosmicTheme.rahuSmoke; label = 'Neutral';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: planets.map((p) {
        final color = CosmicTheme.getPlanetColor(p.planet);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: CosmicTheme.cardGradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // Planet header row
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.15),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Center(child: Text(
                    p.planet.substring(0, 2).toUpperCase(),
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
                  )),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        '${p.planet[0].toUpperCase()}${p.planet.substring(1)}',
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      if (p.isRetrograde) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: CosmicTheme.marsRed.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text('R', style: TextStyle(color: CosmicTheme.marsRed, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text('${p.rashi} ${p.degreeStr}', style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.7), fontSize: 12)),
                  ],
                )),
                _dignityBadge(p.dignity),
              ]),
              const SizedBox(height: 10),
              // Detail row
              Row(children: [
                _DetailItem(label: 'House', value: '${p.houseNumber}'),
                _DetailItem(label: 'Nakshatra', value: p.nakshatra),
                _DetailItem(label: 'Pada', value: '${p.nakshatraPada}'),
                _DetailItem(label: 'Nak Lord', value: p.nakshatraLord.isNotEmpty ? p.nakshatraLord[0].toUpperCase() + p.nakshatraLord.substring(1) : ''),
              ]),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(label, style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
