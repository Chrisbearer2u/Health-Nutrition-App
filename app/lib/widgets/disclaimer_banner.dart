import 'package:flutter/material.dart';

/// The medical disclaimer shown across the app. Google Play health-app
/// policy requires it to be prominent and persistent.
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key, this.compact = false});

  /// When true, renders the single-line summary; otherwise the full text.
  final bool compact;

  static const String fullText =
      'NutriGuide is an informational and educational resource only. It does '
      'not provide medical advice, diagnosis, or treatment. The foods and '
      'supplements described here are general wellness information drawn from '
      'public health sources and peer-reviewed research. Always consult a '
      'qualified healthcare professional before making changes to your diet, '
      'taking supplements, or if you may have a medical condition. Never '
      'delay or disregard professional medical advice because of anything '
      'you read in this app.';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Informational only — not medical advice.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety_outlined,
                    color: scheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Important disclaimer',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: scheme.onSecondaryContainer),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fullText,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
