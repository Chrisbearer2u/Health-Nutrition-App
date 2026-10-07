import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/data/knowledge_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KnowledgeRepository', () {
    test('KnowledgeRepository.empty is initially empty', () {
      final repo = KnowledgeRepository.empty;
      expect(repo.isEmpty, isTrue);
      expect(repo.organs, isEmpty);
      expect(repo.search('heart'), isEmpty);
      expect(repo.organById('heart'), isNull);
      expect(repo.diseaseById('diabetes'), isNull);
    });

    test('KnowledgeRepository loads bundled assets', () async {
      final repo = await KnowledgeRepository.load();

      expect(repo.isEmpty, isFalse);
      expect(repo.organs, isNotEmpty);

      // Verify Heart organ lookup
      final heart = repo.organById('heart');
      expect(heart, isNotNull);
      expect(heart!.name, equals('Heart & Blood Vessels'));

      // Verify search
      final searchResults = repo.search('heart');
      expect(searchResults, isNotEmpty);

      // Verify diseases for organ
      final diseases = repo.diseasesForOrgan('heart');
      expect(diseases, isList);

      // Verify foods for organ
      final foods = repo.foodsForOrgan('heart');
      expect(foods, isList);
    });
  });
}
