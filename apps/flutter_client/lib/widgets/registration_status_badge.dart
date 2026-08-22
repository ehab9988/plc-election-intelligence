import 'package:flutter/material.dart';

import '../core/l10n_ext.dart';
import '../l10n/generated/app_localizations.dart';

/// Never let a "considering" or "rumored" list read as officially
/// registered (section 5) — every status gets a distinct label + color.
class RegistrationStatusBadge extends StatelessWidget {
  final String status;

  const RegistrationStatusBadge({super.key, required this.status});

  String _label(AppLocalizations l10n) => switch (status) {
        'rumored' => l10n.registrationStatusRumored,
        'considering' => l10n.registrationStatusConsidering,
        'announced_intention' => l10n.registrationStatusAnnouncedIntention,
        'submitted_registration' => l10n.registrationStatusSubmittedRegistration,
        'provisional' => l10n.registrationStatusProvisional,
        'officially_approved' => l10n.registrationStatusOfficiallyApproved,
        'rejected' => l10n.registrationStatusRejected,
        'withdrawn' => l10n.registrationStatusWithdrawn,
        'disqualified' => l10n.registrationStatusDisqualified,
        _ => status,
      };

  static const _colors = {
    'rumored': Colors.grey,
    'considering': Colors.grey,
    'announced_intention': Colors.blueGrey,
    'submitted_registration': Colors.blue,
    'provisional': Colors.orange,
    'officially_approved': Colors.green,
    'rejected': Colors.red,
    'withdrawn': Colors.red,
    'disqualified': Colors.red,
  };

  static const _textColors = {
    'rumored': Color(0xFF424242),
    'considering': Color(0xFF424242),
    'announced_intention': Color(0xFF263238),
    'submitted_registration': Color(0xFF0D47A1),
    'provisional': Color(0xFFE65100),
    'officially_approved': Color(0xFF1B5E20),
    'rejected': Color(0xFFB71C1C),
    'withdrawn': Color(0xFFB71C1C),
    'disqualified': Color(0xFFB71C1C),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    final textColor = _textColors[status] ?? const Color(0xFF424242);
    final label = _label(context.l10n);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
