import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/knowledge_repository.dart';
import '../models/models.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/theme_toggle_button.dart';
import 'disease_detail_screen.dart';

/// Detail page for one organ: what it does, foods that support it, and the
/// diseases in the knowledge base associated with it.
class OrganDetailScreen extends StatelessWidget {
  const OrganDetailScreen({super.key, required this.organ});

  final Organ organ;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<KnowledgeRepository>();
    final foods = repo.foodsForOrgan(organ.id);
    final diseases = repo.diseasesForOrgan(organ.id);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(organ.name),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Organ Hero Header Card
          Card(
            color: scheme.primaryContainer,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_iconFor(organ.icon), color: scheme.primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              organ.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onPrimaryContainer,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                organ.system,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    organ.summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Foods & Supplements Section
          _SectionHeader(
            icon: Icons.eco_outlined,
            title: 'Foods & Supplements supporting ${organ.name}',
            count: foods.length,
          ),
          for (final food in foods)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: food.kind == 'supplement'
                      ? scheme.secondaryContainer
                      : scheme.tertiaryContainer,
                  child: Icon(
                    food.kind == 'supplement'
                        ? Icons.medication_outlined
                        : Icons.eco_outlined,
                    color: food.kind == 'supplement'
                        ? scheme.onSecondaryContainer
                        : scheme.onTertiaryContainer,
                    size: 20,
                  ),
                ),
                title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: food.keyNutrients
                        .map((n) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(n, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Associated Diseases Section
          _SectionHeader(
            icon: Icons.coronavirus_outlined,
            title: 'Associated Diseases & Conditions',
            count: diseases.length,
          ),
          if (diseases.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('No entries in local database yet'),
                subtitle: Text('Ask the Health Assistant for guidance on specific conditions.'),
              ),
            )
          else
            for (final disease in diseases)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.errorContainer,
                    child: Icon(Icons.coronavirus_outlined, color: scheme.error, size: 20),
                  ),
                  title: Text(disease.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(disease.category),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DiseaseDetailScreen(disease: disease),
                    ),
                  ),
                ),
              ),

          const SizedBox(height: 12),
          const DisclaimerBanner(),
        ],
      ),
    );
  }

  static IconData _iconFor(String icon) => switch (icon) {
        'heart' => Icons.favorite_outline,
        'brain' => Icons.psychology_outlined,
        'liver' => Icons.water_drop_outlined,
        'kidney' => Icons.filter_alt_outlined,
        'lungs' => Icons.air_outlined,
        'stomach' => Icons.restaurant_menu_outlined,
        'bones' => Icons.accessibility_new_outlined,
        'skin' => Icons.face_outlined,
        'eyes' => Icons.visibility_outlined,
        'pancreas' => Icons.bloodtype_outlined,
        'immune' => Icons.shield_outlined,
        'thyroid' => Icons.mood_outlined,
        _ => Icons.favorite_outline,
      };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (count > 0)
            Badge(
              label: Text('$count'),
              backgroundColor: scheme.primaryContainer,
              textColor: scheme.primary,
            ),
        ],
      ),
    );
  }
}
