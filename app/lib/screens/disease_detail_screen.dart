import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/disclaimer_banner.dart';

/// Full entry for one disease: description, causes, harmful effects, and the
/// foods/supplements nutrition research associates with it.
class DiseaseDetailScreen extends StatelessWidget {
  const DiseaseDetailScreen({super.key, required this.disease});

  final Disease disease;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(disease.name)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(disease.description),
          ),
          const SizedBox(height: 16),
          _BulletSection(
            icon: Icons.help_outline,
            title: 'Causes & risk factors',
            items: disease.causes,
          ),
          _BulletSection(
            icon: Icons.warning_amber_outlined,
            title: 'Harmful effects if unmanaged',
            items: disease.harmfulEffects,
          ),
          _BulletSection(
            icon: Icons.eco_outlined,
            title: 'Natural foods that may help (raw or cooked)',
            items: disease.helpfulFoods,
          ),
          _BulletSection(
            icon: Icons.medication_outlined,
            title: 'Supplements studied for this condition',
            items: disease.helpfulSupplements,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sources',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(disease.sources.join('\n')),
                ],
              ),
            ),
          ),
          const DisclaimerBanner(),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(item)),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
