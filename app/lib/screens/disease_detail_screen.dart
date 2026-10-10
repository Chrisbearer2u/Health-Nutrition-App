import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/theme_toggle_button.dart';

/// Full entry for one disease: description, causes, harmful effects, and the
/// natural foods/supplements nutrition research associates with it.
class DiseaseDetailScreen extends StatelessWidget {
  const DiseaseDetailScreen({super.key, required this.disease});

  final Disease disease;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(disease.name),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Disease Header Card
          Card(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.coronavirus_outlined, color: scheme.error, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              disease.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Chip(
                              label: Text(disease.category),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              labelStyle: TextStyle(fontSize: 11, color: scheme.primary),
                              backgroundColor: scheme.primaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    disease.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          _BulletSection(
            icon: Icons.help_outline,
            iconColor: scheme.primary,
            title: 'Causes & Risk Factors',
            items: disease.causes,
          ),
          _BulletSection(
            icon: Icons.warning_amber_outlined,
            iconColor: scheme.error,
            title: 'Harmful Effects if Unmanaged',
            items: disease.harmfulEffects,
          ),
          _BulletSection(
            icon: Icons.eco_outlined,
            iconColor: Colors.green,
            title: 'Natural Foods that May Help (Raw or Cooked)',
            items: disease.helpfulFoods,
          ),
          _BulletSection(
            icon: Icons.medication_outlined,
            iconColor: scheme.secondary,
            title: 'Supplements Studied for this Condition',
            items: disease.helpfulSupplements,
          ),

          // Reference Sources Card
          if (disease.sources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.library_books_outlined, size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Reference Sources',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        disease.sources.join('\n'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.4,
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
          const DisclaimerBanner(),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
