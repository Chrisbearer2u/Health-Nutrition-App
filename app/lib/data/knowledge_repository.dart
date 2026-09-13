import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/models.dart';

/// Loads the bundled knowledge base (organs, diseases, foods) from assets
/// and provides lookup/search APIs.
///
/// The data layer is intentionally a plain JSON asset bundle: it ships with
/// the app (works offline), can be regenerated from any source (CMS,
/// database dump) without touching app code, and can later be moved to a
/// remote fetch + local cache without changing call sites.
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
}
