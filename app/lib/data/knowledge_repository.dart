import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/models.dart';

/// Loads the bundled knowledge base (organs, diseases, foods) from assets
/// and provides lookup/search APIs, plus on-device health answer generation.
class KnowledgeRepository {
  KnowledgeRepository._(
    this._organs,
    this._diseases,
    this._foods,
  );

  final List<Organ> _organs;
  final List<Disease> _diseases;
  final List<Food> _foods;

  static KnowledgeRepository? _instance;

  /// An empty repository used as FutureProvider placeholder data.
  static final KnowledgeRepository empty = KnowledgeRepository._(
    const [],
    const [],
    const [],
  );

  /// Loads and caches the knowledge base. Safe to call repeatedly.
  static Future<KnowledgeRepository> load() async {
    if (_instance != null) return _instance!;
    final organsJson =
        await rootBundle.loadString('assets/data/organs.json');
    final diseasesJson =
        await rootBundle.loadString('assets/data/diseases.json');
    final foodsJson = await rootBundle.loadString('assets/data/foods.json');

    _instance = KnowledgeRepository._(
      (jsonDecode(organsJson) as List)
          .map((e) => Organ.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      (jsonDecode(diseasesJson) as List)
          .map((e) => Disease.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      (jsonDecode(foodsJson) as List)
          .map((e) => Food.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
    return _instance!;
  }

  List<Organ> get organs => List.unmodifiable(_organs);

  /// True while assets are still loading (placeholder repository).
  bool get isEmpty => _organs.isEmpty && _diseases.isEmpty && _foods.isEmpty;

  Organ? organById(String id) =>
      _organs.where((o) => o.id == id).firstOrNull;

  Disease? diseaseById(String id) =>
      _diseases.where((d) => d.id == id).firstOrNull;

  List<Disease> diseasesForOrgan(String organId) =>
      _diseases.where((d) => d.organId == organId).toList(growable: false);

  List<Food> foodsForOrgan(String organId) =>
      _foods.where((f) => f.supports.contains(organId)).toList(growable: false);

  Food? foodById(String id) => _foods.where((f) => f.id == id).firstOrNull;

  /// Case-insensitive search across organ names and disease names.
  List<Object> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return [
      ..._organs.where((o) => o.name.toLowerCase().contains(q)),
      ..._diseases.where((d) => d.name.toLowerCase().contains(q)),
    ];
  }

  /// Generates a structured health and nutrition answer from the local database.
  String generateAnswer(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return 'Please ask a question about any disease, organ system, food, or supplement.';
    }

    // 1. Match disease
    final matchedDiseases = _diseases.where((d) {
      final nameLower = d.name.toLowerCase();
      final idLower = d.id.toLowerCase();
      return nameLower.contains(q) ||
          q.contains(nameLower) ||
          idLower.contains(q) ||
          q.contains(idLower);
    }).toList();

    if (matchedDiseases.isNotEmpty) {
      final buffer = StringBuffer();
      for (final d in matchedDiseases.take(2)) {
        buffer.writeln('### 🏥 ${d.name}');
        buffer.writeln('**Category:** ${d.category}\n');
        buffer.writeln('${d.description}\n');

        if (d.causes.isNotEmpty) {
          buffer.writeln('#### ⚠️ Causes & Risk Factors:');
          for (final c in d.causes) {
            buffer.writeln('• $c');
          }
          buffer.writeln();
        }

        if (d.harmfulEffects.isNotEmpty) {
          buffer.writeln('#### ⚡ Harmful Effects if Unmanaged:');
          for (final h in d.harmfulEffects) {
            buffer.writeln('• $h');
          }
          buffer.writeln();
        }

        if (d.helpfulFoods.isNotEmpty) {
          buffer.writeln('#### 🥗 Recommended Natural Foods (Raw or Cooked):');
          for (final f in d.helpfulFoods) {
            buffer.writeln('• $f');
          }
          buffer.writeln();
        }

        if (d.helpfulSupplements.isNotEmpty) {
          buffer.writeln('#### 💊 Studied World-Known Supplements:');
          for (final s in d.helpfulSupplements) {
            buffer.writeln('• $s');
          }
          buffer.writeln();
        }

        if (d.sources.isNotEmpty) {
          buffer.writeln('*Sources: ${d.sources.join(", ")}*');
          buffer.writeln();
        }
      }
      return buffer.toString().trim();
    }

    // 2. Match organ
    final matchedOrgans = _organs.where((o) {
      final nameLower = o.name.toLowerCase();
      final sysLower = o.system.toLowerCase();
      final idLower = o.id.toLowerCase();
      return nameLower.contains(q) ||
          q.contains(nameLower) ||
          sysLower.contains(q) ||
          idLower.contains(q);
    }).toList();

    if (matchedOrgans.isNotEmpty) {
      final organ = matchedOrgans.first;
      final supportingFoods = foodsForOrgan(organ.id);
      final relatedDiseases = diseasesForOrgan(organ.id);

      final buffer = StringBuffer();
      buffer.writeln('### 🫀 ${organ.name}');
      buffer.writeln('**System:** ${organ.system}\n');
      buffer.writeln('${organ.summary}\n');

      if (supportingFoods.isNotEmpty) {
        buffer.writeln('#### 🥗 Foods & Supplements supporting ${organ.name}:');
        for (final f in supportingFoods) {
          buffer.writeln('• **${f.name}** (${f.kind}): ${f.notes}');
        }
        buffer.writeln();
      }

      if (relatedDiseases.isNotEmpty) {
        buffer.writeln('#### 🩺 Associated Health Conditions:');
        for (final d in relatedDiseases) {
          buffer.writeln('• **${d.name}**: ${d.description}');
        }
        buffer.writeln();
      }
      return buffer.toString().trim();
    }

    // 3. Match foods or supplements
    final matchedFoods = _foods.where((f) {
      final nameLower = f.name.toLowerCase();
      return nameLower.contains(q) || q.contains(nameLower);
    }).toList();

    if (matchedFoods.isNotEmpty) {
      final buffer = StringBuffer();
      buffer.writeln('### 🌿 Nutritional Guidance\n');
      for (final f in matchedFoods.take(3)) {
        buffer.writeln('#### ${f.name} (${f.kind})');
        buffer.writeln('**Key Nutrients:** ${f.keyNutrients.join(", ")}');
        buffer.writeln(
            '**Organs Supported:** ${f.supports.map((s) => organById(s)?.name ?? s).join(", ")}');
        buffer.writeln('**Notes:** ${f.notes}\n');
      }
      return buffer.toString().trim();
    }

    // 4. Keyword search across descriptions, causes, and foods
    final keywordDiseases = _diseases.where((d) {
      return d.description.toLowerCase().contains(q) ||
          d.causes.any((c) => c.toLowerCase().contains(q)) ||
          d.helpfulFoods.any((f) => f.toLowerCase().contains(q)) ||
          d.helpfulSupplements.any((s) => s.toLowerCase().contains(q));
    }).toList();

    if (keywordDiseases.isNotEmpty) {
      final buffer = StringBuffer();
      buffer.writeln('### 💡 Related Health Topics for "$query"\n');
      for (final d in keywordDiseases.take(2)) {
        buffer.writeln('#### 🏥 ${d.name}');
        buffer.writeln('${d.description}\n');
        buffer.writeln('**Helpful Foods:** ${d.helpfulFoods.take(4).join(", ")}');
        buffer.writeln(
            '**Supplements:** ${d.helpfulSupplements.take(3).join(", ")}\n');
      }
      return buffer.toString().trim();
    }

    // 5. General default response
    return '### 🌿 NutriGuide Health & Nutrition Assistant\n\n'
        'I am ready to help you with information on human diseases, their causes, harmful effects, and supportive natural foods or supplements.\n\n'
        '**Explore topics you can ask about:**\n'
        '• **Cardiovascular:** Hypertension, Atherosclerosis, Coronary Heart Disease\n'
        '• **Brain & Nervous System:** Depression, Alzheimer\'s Disease, Migraine\n'
        '• **Metabolic & Organs:** Type 2 Diabetes, Non-Alcoholic Fatty Liver Disease, Chronic Kidney Disease, Kidney Stones\n'
        '• **Respiratory & Digestive:** Asthma, COPD, GERD, Peptic Ulcers, IBS, Constipation\n'
        '• **Bones, Joints & Skin:** Osteoporosis, Arthritis, Gout, Acne, Eczema\n'
        '• **Immune, Eyes & Thyroid:** Common Cold, Macular Degeneration, Cataracts, Dry Eye, Hypothyroidism\n\n'
        'Try asking a question like *"Tell me about Type 2 Diabetes"* or *"What foods support the liver?"*';
  }
}
