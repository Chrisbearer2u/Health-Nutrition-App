import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/knowledge_repository.dart';
import '../models/models.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/theme_toggle_button.dart';
import 'disease_detail_screen.dart';
import 'organ_detail_screen.dart';

/// Section (a): browse the knowledge base by organ / body system, with
/// interactive system category filtering and search.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  String _selectedSystem = 'All';

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<KnowledgeRepository>();
    final scheme = Theme.of(context).colorScheme;

    // Collect unique body systems for category chips
    final systems = ['All', ...repo.organs.map((o) => o.system).toSet()];

    // Filter organs based on selected category chip
    final filteredOrgans = _selectedSystem == 'All'
        ? repo.organs
        : repo.organs.where((o) => o.system == _selectedSystem).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.health_and_safety, color: scheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('NutriGuide'),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
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
                // Hero Header Banner
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primaryContainer,
                          scheme.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Organ Systems & Clinical Nutrition',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Explore how specific foods & natural supplements support vital body organs.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SearchAnchor(
                    builder: (context, controller) => SearchBar(
                      controller: controller,
                      hintText: 'Search organs or diseases…',
                      leading: Icon(Icons.search, color: scheme.primary),
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
                            leading: CircleAvatar(
                              backgroundColor: item is Organ
                                  ? scheme.primaryContainer
                                  : scheme.errorContainer,
                              child: Icon(
                                item is Organ
                                    ? Icons.favorite_outline
                                    : Icons.coronavirus_outlined,
                                color: item is Organ
                                    ? scheme.primary
                                    : scheme.error,
                                size: 20,
                              ),
                            ),
                            title: Text(item is Organ
                                ? item.name
                                : (item as Disease).name),
                            subtitle: Text(item is Organ
                                ? 'Organ / system'
                                : 'Disease / condition'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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

                // System Filter Chips
                if (systems.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: systems.map((sys) {
                        final selected = sys == _selectedSystem;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: selected,
                            label: Text(sys),
                            onSelected: (_) => setState(() => _selectedSystem = sys),
                            selectedColor: scheme.primaryContainer,
                            checkmarkColor: scheme.primary,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const DisclaimerBanner(compact: true),

                // Organ List
                Expanded(
                  child: _OrganList(organs: filteredOrgans),
                ),
              ],
            ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('About NutriGuide',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
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
    final scheme = Theme.of(context).colorScheme;

    if (organs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text('No organ systems found',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: organs.length,
      itemBuilder: (context, i) {
        final organ = organs[i];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OrganDetailScreen(organ: organ),
            )),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _iconFor(organ.icon),
                      color: scheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organ.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            organ.system,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.outline),
                ],
              ),
            ),
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
