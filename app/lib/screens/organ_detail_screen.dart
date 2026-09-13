import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/knowledge_repository.dart';
import '../models/models.dart';
import '../widgets/disclaimer_banner.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(organ.name)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              organ.system,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(organ.summary),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Foods & supplements that support ${organ.name.toLowerCase()}',
            children: [
              for (final food in foods)
                ListTile(
                  leading: Icon(
                    food.kind == 'supplement'
                        ? Icons.medication_outlined
                        : Icons.eco_outlined,
                  ),
                  title: Text(food.name),
                  subtitle: Text(food.keyNutrients.join(', '),
                      maxLines: 1),
                ),
            ],
          ),
          _Section(
            title: 'Related diseases & conditions',
            children: diseases.isEmpty
                ? [
                    const ListTile(
                      leading: Icon(Icons.search_off),
                      title: Text('No entries in the local database yet — '
                          'ask the Assistant instead.'),
                    ),
                  ]
                : [
                    for (final disease in diseases)
                      ListTile(
                        leading: const Icon(Icons.coronavirus_outlined),
                        title: Text(disease.name),
                        subtitle: Text(disease.category),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                DiseaseDetailScreen(disease: disease),
                          ),
                        ),
                      ),
                  ],
          ),
          const DisclaimerBanner(),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }
}
