import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/models/models.dart';

void main() {
  group('Organ Model', () {
    test('Organ.fromJson parses correctly', () {
      final json = {
        'id': 'liver',
        'name': 'Liver',
        'system': 'Digestive',
        'icon': 'liver_icon',
        'summary': 'Filters toxins and processes nutrients.',
        'supportingFoods': ['garlic', 'green_tea'],
        'diseaseIds': ['fatty_liver', 'hepatitis'],
      };

      final organ = Organ.fromJson(json);

      expect(organ.id, equals('liver'));
      expect(organ.name, equals('Liver'));
      expect(organ.system, equals('Digestive'));
      expect(organ.supportingFoods, equals(['garlic', 'green_tea']));
      expect(organ.diseaseIds, equals(['fatty_liver', 'hepatitis']));
    });
  });

  group('Disease Model', () {
    test('Disease.fromJson parses correctly', () {
      final json = {
        'id': 'type2_diabetes',
        'name': 'Type 2 Diabetes',
        'organId': 'pancreas',
        'category': 'Metabolic',
        'description': 'Impairs blood sugar regulation.',
        'causes': ['Insulin resistance', 'Sedentary lifestyle'],
        'harmfulEffects': ['Nerve damage', 'Kidney strain'],
        'helpfulFoods': ['Cinnamon', 'Leafy greens'],
        'helpfulSupplements': ['Chromium', 'Berberine'],
        'sources': ['NIH ODS', 'WHO'],
      };

      final disease = Disease.fromJson(json);

      expect(disease.id, equals('type2_diabetes'));
      expect(disease.name, equals('Type 2 Diabetes'));
      expect(disease.organId, equals('pancreas'));
      expect(disease.causes.length, equals(2));
      expect(disease.helpfulFoods.first, equals('Cinnamon'));
      expect(disease.sources.last, equals('WHO'));
    });
  });

  group('Food Model', () {
    test('Food.fromJson parses correctly', () {
      final json = {
        'id': 'garlic',
        'name': 'Garlic',
        'kind': 'food',
        'keyNutrients': ['Allicin', 'Selenium'],
        'supports': ['liver', 'heart'],
        'notes': 'Promotes antioxidant enzyme production.',
      };

      final food = Food.fromJson(json);

      expect(food.id, equals('garlic'));
      expect(food.name, equals('Garlic'));
      expect(food.kind, equals('food'));
      expect(food.keyNutrients, equals(['Allicin', 'Selenium']));
      expect(food.supports, equals(['liver', 'heart']));
    });
  });

  group('ChatMessage Model', () {
    test('ChatMessage constructs user and assistant messages', () {
      final userMsg = ChatMessage.user('Hello');
      final assistantMsg = ChatMessage.assistant('Hi there');

      expect(userMsg.isUser, isTrue);
      expect(userMsg.role, equals(Role.user));
      expect(userMsg.content, equals('Hello'));

      expect(assistantMsg.isUser, isFalse);
      expect(assistantMsg.role, equals(Role.assistant));
      expect(assistantMsg.content, equals('Hi there'));
    });
  });
}
