import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// "Forecast updated 18 minutes ago" style banner (section 66) — every
/// screen showing dynamic data must show this rather than implying the
/// number is live.
class FreshnessBanner extends StatelessWidget {
  final DateTime timestamp;
  final String labelPrefix;

  const FreshnessBanner({super.key, required this.timestamp, this.labelPrefix = 'Updated'});

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().toUtc().difference(timestamp.toUtc());
    final text = age.inMinutes < 1
        ? 'just now'
        : age.inMinutes < 60
            ? '${age.inMinutes} min ago'
            : age.inHours < 24
                ? '${age.inHours} h ago'
                : DateFormat.yMMMd().format(timestamp);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          '$labelPrefix $text',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
      ],
    );
  }
}

/// Bold, unmissable label distinguishing a modeled forecast from an
/// official result (section 61 election-day mode; section 80 rule #12/#13).
class ForecastLabel extends StatelessWidget {
  final bool isOfficial;
  final String text;

  const ForecastLabel({super.key, this.isOfficial = false, this.text = 'FORECAST'});

  @override
  Widget build(BuildContext context) {
    final color = isOfficial ? Colors.green.shade800 : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }
}
