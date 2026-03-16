import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/models.dart';
import '../theme/cosmic_theme.dart';

class DashaTimeline extends StatelessWidget {
  final List<DashaPeriod> dashas;
  const DashaTimeline({super.key, required this.dashas});

  @override
  Widget build(BuildContext context) {
    if (dashas.isEmpty) {
      return const Center(child: Text('No dasha data available', style: TextStyle(color: CosmicTheme.rahuSmoke)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vimshottari Maha Dasha Timeline',
          style: TextStyle(color: CosmicTheme.starGold, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Dasha periods reveal the timing of karmic activations in life.',
          style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.6), fontSize: 12)),
        const SizedBox(height: 20),
        ...dashas.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value;
          final color = CosmicTheme.getPlanetColor(d.planet);
          final isCurrent = d.isCurrent;
          final isPast = DateTime.tryParse(d.endDate)?.isBefore(DateTime.now()) ?? false;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line
              SizedBox(
                width: 40,
                child: Column(children: [
                  Container(
                    width: isCurrent ? 18 : 12,
                    height: isCurrent ? 18 : 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent ? color : isPast ? color.withOpacity(0.3) : CosmicTheme.surfaceDark,
                      border: Border.all(color: color, width: isCurrent ? 2.5 : 1),
                      boxShadow: isCurrent ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : [],
                    ),
                  ),
                  if (i < dashas.length - 1)
                    Container(
                      width: 2, height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [color.withOpacity(isPast ? 0.2 : 0.5), CosmicTheme.getPlanetColor(dashas[math.min(i + 1, dashas.length - 1)].planet).withOpacity(0.5)],
                        ),
                      ),
                    ),
                ]),
              ),
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: isCurrent
                        ? LinearGradient(colors: [color.withOpacity(0.12), CosmicTheme.cardBg])
                        : CosmicTheme.cardGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isCurrent ? color.withOpacity(0.5) : CosmicTheme.borderGlow.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${d.planet[0].toUpperCase()}${d.planet.substring(1)} Dasha',
                            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        const Spacer(),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: CosmicTheme.venusGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('ACTIVE', style: TextStyle(color: CosmicTheme.venusGreen, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          ),
                        if (isPast)
                          Text('Past', style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 10)),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.calendar_today, size: 12, color: CosmicTheme.rahuSmoke),
                        const SizedBox(width: 6),
                        Text('${_formatDate(d.startDate)}  →  ${_formatDate(d.endDate)}',
                          style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.7), fontSize: 11)),
                      ]),
                      const SizedBox(height: 4),
                      Text('${d.durationYears.toStringAsFixed(1)} years',
                        style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 10)),
                      if (isCurrent) ...[
                        const SizedBox(height: 8),
                        _ProgressBar(startDate: d.startDate, endDate: d.endDate, color: color),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length < 3) return date;
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${months[m]} ${parts[0]}';
  }
}

// Need math for min
class _ProgressBar extends StatelessWidget {
  final String startDate, endDate;
  final Color color;
  const _ProgressBar({required this.startDate, required this.endDate, required this.color});

  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse(startDate);
    final end = DateTime.tryParse(endDate);
    if (start == null || end == null) return const SizedBox.shrink();
    final total = end.difference(start).inDays.toDouble();
    final elapsed = DateTime.now().difference(start).inDays.toDouble();
    final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(progress * 100).toStringAsFixed(0)}% completed', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            Text('${(total - elapsed).toInt()} days remaining', style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: CosmicTheme.surfaceDark,
            color: color,
          ),
        ),
      ],
    );
  }
}
