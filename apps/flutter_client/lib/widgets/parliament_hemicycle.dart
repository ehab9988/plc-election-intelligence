import 'dart:math' as math;

import 'package:flutter/material.dart';

class HemicycleSeatGroup {
  final String label;
  final int seats;
  final Color color;

  const HemicycleSeatGroup({required this.label, required this.seats, required this.color});
}

/// Renders a 132-seat (or any total) hemicycle, arranging seats in
/// concentric arcs. Party order determines left-to-right grouping —
/// purely visual, not politically meaningful (section 46 neutrality).
class ParliamentHemicycle extends StatelessWidget {
  final List<HemicycleSeatGroup> groups;
  final int totalSeats;

  const ParliamentHemicycle({super.key, required this.groups, required this.totalSeats});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2,
      child: CustomPaint(
        painter: _HemicyclePainter(groups: groups, totalSeats: totalSeats),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _HemicyclePainter extends CustomPainter {
  final List<HemicycleSeatGroup> groups;
  final int totalSeats;

  _HemicyclePainter({required this.groups, required this.totalSeats});

  @override
  void paint(Canvas canvas, Size size) {
    final seatColors = <Color>[
      for (final g in groups) ...List.filled(g.seats, g.color),
    ];
    final placeholderCount = totalSeats - seatColors.length;
    if (placeholderCount > 0) {
      seatColors.addAll(List.filled(placeholderCount, Colors.grey.shade300));
    }

    const rings = 7;
    final seatsPerRing = _distributeAcrossRings(seatColors.length, rings);

    final center = Offset(size.width / 2, size.height);
    final maxRadius = math.min(size.width / 2, size.height) - 8;
    final ringGap = maxRadius / rings;

    var seatIndex = 0;
    for (var ring = 0; ring < rings; ring++) {
      final radius = ringGap * (ring + 1.4);
      final countInRing = seatsPerRing[ring];
      if (countInRing == 0) continue;
      for (var i = 0; i < countInRing; i++) {
        final t = countInRing == 1 ? 0.5 : i / (countInRing - 1);
        final angle = math.pi - (t * math.pi);
        final dx = center.dx + radius * math.cos(angle);
        final dy = center.dy - radius * math.sin(angle);
        final paint = Paint()..color = seatIndex < seatColors.length ? seatColors[seatIndex] : Colors.grey.shade300;
        canvas.drawCircle(Offset(dx, dy), 4.2, paint);
        seatIndex++;
      }
    }
  }

  List<int> _distributeAcrossRings(int total, int rings) {
    // Outer rings hold more seats (roughly proportional to ring index+1)
    // so density looks even, matching typical hemicycle charts.
    final weights = List.generate(rings, (i) => i + 1);
    final weightSum = weights.fold<int>(0, (a, b) => a + b);
    final counts = weights.map((w) => (total * w / weightSum).round()).toList();
    var diff = total - counts.fold<int>(0, (a, b) => a + b);
    var idx = rings - 1;
    while (diff != 0) {
      counts[idx] += diff > 0 ? 1 : -1;
      diff += diff > 0 ? -1 : 1;
      idx = (idx - 1 + rings) % rings;
    }
    return counts;
  }

  @override
  bool shouldRepaint(covariant _HemicyclePainter oldDelegate) =>
      oldDelegate.groups != groups || oldDelegate.totalSeats != totalSeats;
}
