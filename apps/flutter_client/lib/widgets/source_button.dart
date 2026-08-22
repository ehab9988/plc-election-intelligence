import 'package:flutter/material.dart';

/// "View source" affordance next to any important number (section 65) —
/// makes it hard for a figure to appear in the app without provenance.
class SourceButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  const SourceButton({super.key, this.onTap, this.label = 'View source'});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.link, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
