import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/knowledge_repository.dart';
import '../models/models.dart';
import '../widgets/disclaimer_banner.dart';
import 'disease_detail_screen.dart';
import 'organ_detail_screen.dart';

/// Section (a): browse the knowledge base by organ / body system, with
/// search across organs and diseases.
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<KnowledgeRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriGuide'),
        actions: [
          IconButton(
            tooltip: 'About & disclaimer',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: repo.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SearchAnchor(
                    builder: (context, controller) => SearchBar(
                      controller: controller,
                      hintText: 'Search organs or diseases…',
                      leading: const Icon(Icons.search),
                      onTap: () => controller.openView(),
                      onChanged: (_) => controller.openView(),
                    ),
                    suggestionsBuilder: (context, controller) {
                      final results = repo.search(controller.text);
                      if (results.isEmpty && controller.text.isNotEmpty) {
                        return [
                          const ListTile(
                            title: Text('No matches found'),
                            leading: Icon(Icons.search_off),
                          ),
                        ];
                      }
                      return results.map((item) => ListTile(
                            leading: Icon(item is Organ
                                ? Icons.favorite_outline
                                : Icons.coronavirus_outlined),
                            title: Text(item is Organ
                                ? item.name
                                : (item as Disease).name),
                            subtitle: Text(item is Organ
                                ? 'Organ / system'
                                : 'Disease / condition'),
                            onTap: () {
                              controller.closeView(null);
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => item is Organ
                                    ? OrganDetailScreen(organ: item)
                                    : DiseaseDetailScreen(disease: item as Disease),
                              ));
                            },
                          ));
                    },
                  ),
                ),
                const DisclaimerBanner(compact: true),
                Expanded(child: _OrganList(organs: repo.organs)),
              ],
            ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About NutriGuide',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            DisclaimerBanner(),
          ],
        ),
      ),
    );
  }
}

class _OrganList extends StatelessWidget {
  const _OrganList({required this.organs});

  final List<Organ> organs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: organs.length,
      itemBuilder: (context, i) {
        final organ = organs[i];
        return Card(
          child: ListTile(
            leading: Icon(_iconFor(organ.icon)),
            title: Text(organ.name),
            subtitle: Text(organ.system, maxLines: 1),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OrganDetailScreen(organ: organ),
            )),
          ),
        );
      },
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
