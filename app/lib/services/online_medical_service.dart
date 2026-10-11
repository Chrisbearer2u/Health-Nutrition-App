import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches medical and disease information from online health repositories
/// (e.g. Wikipedia REST API) for any human disease not in the local bundle.
class OnlineMedicalService {
  OnlineMedicalService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetches medical details for [diseaseQuery] over the internet.
  /// Returns a formatted Markdown string or null if not found.
  Future<String?> fetchDiseaseInfo(String diseaseQuery) async {
    try {
      final query = diseaseQuery.trim();
      if (query.isEmpty) return null;

      // 1. Search for matching medical article
      final searchUri = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(query)}&format=json&origin=*',
      );

      final searchResponse = await _client.get(searchUri).timeout(const Duration(seconds: 4));
      if (searchResponse.statusCode != 200) return null;

      final searchData = jsonDecode(searchResponse.body) as Map<String, dynamic>;
      final searchResults =
          (searchData['query']?['search'] as List?)?.cast<Map<String, dynamic>>();

      if (searchResults == null || searchResults.isEmpty) return null;

      // Select top matching article title
      final pageTitle = searchResults.first['title'] as String;

      // 2. Fetch page summary
      final summaryUri = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(pageTitle.replaceAll(" ", "_"))}',
      );

      final summaryResponse = await _client.get(summaryUri).timeout(const Duration(seconds: 4));
      if (summaryResponse.statusCode != 200) return null;

      final summaryData = jsonDecode(summaryResponse.body) as Map<String, dynamic>;
      final extract = summaryData['extract'] as String?;
      final description = summaryData['description'] as String?;

      if (extract == null || extract.trim().isEmpty) return null;

      final buffer = StringBuffer();
      buffer.writeln('### 🏥 $pageTitle (Web Health Repository)');
      if (description != null && description.isNotEmpty) {
        buffer.writeln('**Category:** ${description[0].toUpperCase()}${description.substring(1)}\n');
      }
      buffer.writeln('$extract\n');

      buffer.writeln('#### 🥗 General Health & Lifestyle Support:');
      buffer.writeln('• Maintain a balanced, nutrient-dense diet rich in antioxidants, fruits, and vegetables.');
      buffer.writeln('• Stay hydrated with adequate water intake and manage stress.');
      buffer.writeln('• Consult a qualified medical practitioner for diagnosis and individualized treatment.\n');

      buffer.writeln('*Source: Online Medical Repository & Wikipedia Health Database*');

      return buffer.toString().trim();
    } catch (_) {
      return null;
    }
  }
}
