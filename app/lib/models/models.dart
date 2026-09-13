/// Data models for the NutriGuide knowledge base.
///
/// The models mirror the JSON schema in `assets/data/*.json`
/// (documented in `docs/DATA_SCHEMA.md`).
library;

/// A body system or organ the user can browse (e.g. Heart, Liver).
class Organ {
  const Organ({
    required this.id,
    required this.name,
    required this.system,
    required this.icon,
    required this.summary,
    required this.supportingFoods,
    required this.diseaseIds,
  });

  factory Organ.fromJson(Map<String, dynamic> json) => Organ(
        id: json['id'] as String,
        name: json['name'] as String,
        system: json['system'] as String,
        icon: json['icon'] as String,
        summary: json['summary'] as String,
        supportingFoods:
            (json['supportingFoods'] as List).cast<String>(),
        diseaseIds: (json['diseaseIds'] as List).cast<String>(),
      );

  final String id;
  final String name;
  final String system;
  final String icon;
  final String summary;

  /// Food/supplement IDs from `foods.json` that generally support this organ.
  final List<String> supportingFoods;

  /// Disease IDs from `diseases.json` associated with this organ.
  final List<String> diseaseIds;
}

/// A disease/condition entry with general wellness information.
class Disease {
  const Disease({
    required this.id,
    required this.name,
    required this.organId,
    required this.category,
    required this.description,
    required this.causes,
    required this.harmfulEffects,
    required this.helpfulFoods,
    required this.helpfulSupplements,
    required this.sources,
  });

  factory Disease.fromJson(Map<String, dynamic> json) => Disease(
        id: json['id'] as String,
        name: json['name'] as String,
        organId: json['organId'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        causes: (json['causes'] as List).cast<String>(),
        harmfulEffects: (json['harmfulEffects'] as List).cast<String>(),
        helpfulFoods: (json['helpfulFoods'] as List).cast<String>(),
        helpfulSupplements:
            (json['helpfulSupplements'] as List).cast<String>(),
        sources: (json['sources'] as List).cast<String>(),
      );

  final String id;
  final String name;
  final String organId;
  final String category;

  /// Plain-language description of the disease.
  final String description;

  /// Known/risk causes — informational, not diagnostic.
  final List<String> causes;

  /// Harmful effects on the body if unmanaged.
  final List<String> harmfulEffects;

  /// Human-readable food names (raw or cooked) associated in nutrition
  /// research with managing or reducing risk of this condition.
  final List<String> helpfulFoods;

  /// World-known supplements studied for this condition.
  final List<String> helpfulSupplements;

  /// Reputable sources backing the entry (NIH ODS, WHO, peer review).
  final List<String> sources;
}

/// A food or supplement entry in the knowledge base.
class Food {
  const Food({
    required this.id,
    required this.name,
    required this.kind,
    required this.keyNutrients,
    required this.supports,
    required this.notes,
  });

  factory Food.fromJson(Map<String, dynamic> json) => Food(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: json['kind'] as String, // "food" | "supplement"
        keyNutrients: (json['keyNutrients'] as List).cast<String>(),
        supports: (json['supports'] as List).cast<String>(),
        notes: json['notes'] as String,
      );

  final String id;
  final String name;
  final String kind;
  final List<String> keyNutrients;

  /// Organ IDs this item generally supports.
  final List<String> supports;
  final String notes;
}

/// A chat message in the assistant conversation.
class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  factory ChatMessage.user(String text) =>
      ChatMessage(role: Role.user, content: text);

  factory ChatMessage.assistant(String text) =>
      ChatMessage(role: Role.assistant, content: text);

  final Role role;
  final String content;

  bool get isUser => role == Role.user;
}

enum Role { user, assistant }
