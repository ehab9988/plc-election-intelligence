import 'package:flutter/material.dart';

/// Renders a median value plus an 80% range bar — never a bare number
/// (section 2, 58). `low`/`high`/`median` share a scale (0..max).
class UncertaintyRangeBar extends StatelessWidget {
  final double low;
  final double median;
  final double high;
  final double max;
  final Color color;
  final String Function(double) formatValue;

  const UncertaintyRangeBar({
    super.key,
    required this.low,
    required this.median,
    required this.high,
    required this.max,
    required this.color,
    required this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      double toX(double v) => (v.clamp(0, max) / max) * width;
      return SizedBox(
        height: 28,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(height: 6, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3))),
            Positioned(
              left: toX(low),
              child: Container(
                width: (toX(high) - toX(low)).clamp(2, width),
                height: 6,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(3)),
              ),
            ),
            Positioned(
              left: (toX(median) - 5).clamp(0, width - 10),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Compact "median (low–high)" text chip for tables/lists.
class RangeText extends StatelessWidget {
  final String median;
  final String low;
  final String high;

  const RangeText({super.key, required this.median, required this.low, required this.high});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          TextSpan(text: median, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: '  ($low–$high)',
            style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
