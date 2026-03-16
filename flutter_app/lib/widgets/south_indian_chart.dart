import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/models.dart';
import '../theme/cosmic_theme.dart';

class SouthIndianChart extends StatelessWidget {
  final Kundali kundali;
  const SouthIndianChart({super.key, required this.kundali});

  // South Indian chart house positions (fixed sign layout):
  // Pisces | Aries   | Taurus  | Gemini
  // Aqua   |                   | Cancer
  // Capri  |                   | Leo
  // Sagit  | Scorpio | Libra   | Virgo
  static const _signPositions = {
    'Pisces': 0, 'Aries': 1, 'Taurus': 2, 'Gemini': 3,
    'Cancer': 7, 'Leo': 11, 'Virgo': 15,
    'Libra': 14, 'Scorpio': 13, 'Sagittarius': 12,
    'Capricorn': 8, 'Aquarius': 4,
  };

  // Grid cell positions for the 4x4 layout (row, col) → cell index
  // Outer ring cells: 0-15 mapped as shown above
  static const List<List<int>> _gridCells = [
    [0, 1, 2, 3],   // row 0: Pisces, Aries, Taurus, Gemini
    [4, -1, -1, 7],  // row 1: Aquarius, (center), (center), Cancer
    [8, -1, -1, 11], // row 2: Capricorn, (center), (center), Leo
    [12, 13, 14, 15], // row 3: Sagittarius, Scorpio, Libra, Virgo
  ];

  static const List<String> _signOrder = [
    'Pisces', 'Aries', 'Taurus', 'Gemini',
    'Aquarius', '', '', 'Cancer',
    'Capricorn', '', '', 'Leo',
    'Sagittarius', 'Scorpio', 'Libra', 'Virgo',
  ];

  static const List<String> _signAbbr = [
    'Pi', 'Ar', 'Ta', 'Ge', 'Aq', '', '', 'Cn',
    'Cp', '', '', 'Le', 'Sg', 'Sc', 'Li', 'Vi',
  ];

  List<PlanetPosition> _planetsInSign(String sign) {
    return kundali.planets.values.where((p) => p.rashi == sign).toList();
  }

  String _planetAbbr(String planet) {
    const abbrs = {
      'sun': 'Su', 'moon': 'Mo', 'mars': 'Ma', 'mercury': 'Me',
      'jupiter': 'Ju', 'venus': 'Ve', 'saturn': 'Sa', 'rahu': 'Ra', 'ketu': 'Ke',
    };
    return abbrs[planet.toLowerCase()] ?? planet.substring(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final ascSign = kundali.ascendantRashi;
    final cellSize = (MediaQuery.of(context).size.width - 48) / 4;

    return Container(
      decoration: BoxDecoration(
        gradient: CosmicTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CosmicTheme.starGold.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: CosmicTheme.starGold.withOpacity(0.08), blurRadius: 20)],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Rashi Chart (D1)', style: TextStyle(color: CosmicTheme.starGold, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          // 4x4 grid
          ...List.generate(4, (row) => Row(
            children: List.generate(4, (col) {
              final idx = row * 4 + col;
              final sign = _signOrder[idx];

              // Center cells
              if (sign.isEmpty) {
                if (row == 1 && col == 1) {
                  // Center block spanning 2x2 — only draw in top-left of center
                  return SizedBox(
                    width: cellSize, height: cellSize,
                    child: Container(
                      decoration: BoxDecoration(
                        color: CosmicTheme.deepSpace.withOpacity(0.5),
                        border: Border.all(color: CosmicTheme.borderGlow.withOpacity(0.3)),
                      ),
                      child: Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: CosmicTheme.starGold.withOpacity(0.6), size: 20),
                          const SizedBox(height: 4),
                          Text('RASHI', style: TextStyle(color: CosmicTheme.starGold.withOpacity(0.5), fontSize: 9, letterSpacing: 2)),
                        ],
                      )),
                    ),
                  );
                }
                return SizedBox(
                  width: cellSize, height: cellSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CosmicTheme.deepSpace.withOpacity(0.5),
                      border: Border.all(color: CosmicTheme.borderGlow.withOpacity(0.3)),
                    ),
                  ),
                );
              }

              final planets = _planetsInSign(sign);
              final isAsc = sign == ascSign;

              return SizedBox(
                width: cellSize, height: cellSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: isAsc ? CosmicTheme.starGold.withOpacity(0.08) : Colors.transparent,
                    border: Border.all(
                      color: isAsc ? CosmicTheme.starGold.withOpacity(0.5) : CosmicTheme.borderGlow.withOpacity(0.4),
                      width: isAsc ? 1.5 : 0.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sign label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_signAbbr[idx],
                              style: TextStyle(
                                color: isAsc ? CosmicTheme.starGold : CosmicTheme.rahuSmoke,
                                fontSize: 9, fontWeight: FontWeight.w700,
                              )),
                            if (isAsc) Text('Asc', style: TextStyle(color: CosmicTheme.starGold, fontSize: 7, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const Spacer(),
                        // Planets in this sign
                        if (planets.isNotEmpty)
                          Wrap(
                            spacing: 2, runSpacing: 1,
                            children: planets.map((p) {
                              final c = CosmicTheme.getPlanetColor(p.planet);
                              return Text(
                                '${_planetAbbr(p.planet)}${p.isRetrograde ? "ᴿ" : ""}',
                                style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700),
                              );
                            }).toList(),
                          ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            }),
          )),
          const SizedBox(height: 8),
          // Legend
          Wrap(
            spacing: 10, runSpacing: 4,
            alignment: WrapAlignment.center,
            children: kundali.planets.values.map((p) {
              final c = CosmicTheme.getPlanetColor(p.planet);
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
                const SizedBox(width: 3),
                Text('${_planetAbbr(p.planet)} ${p.degreeStr}',
                  style: TextStyle(color: c.withOpacity(0.8), fontSize: 9)),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}
