import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// The exact greeting the assistant shows when the chat is first opened.
/// This text is fixed by product requirement and rendered client-side so it
/// is byte-for-byte identical on every launch, regardless of network state.
const String kAssistantGreeting =
    'Ask me what you want to know about any particular human disease and I '
    'will tell you everything about the disease, its cause, its harmful '
    'effects, and the most appropriate world-known natural food or food '
    'supplement that can cure or suppress it harmful effects.';

/// Backend base URL. Override at build time with:
///   flutter build appbundle \
///     --dart-define=API_BASE_URL=https://your-deployment.example.com
const String _defaultBaseUrl = 'http://10.0.2.2:8080';

/// Talks to the NutriGuide backend proxy, which holds the LLM credentials
/// server-side. The app never sees an API key.
class ChatService {
  ChatService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl =>
      const String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl);

  /// Optional shared secret mirroring the backend's APP_KEY env var.
  static const String _appKey = String.fromEnvironment('APP_KEY');

  /// Sends the conversation to the backend and streams the assistant's
  /// reply token-by-token via [onDelta]. Returns the full response text.
  Future<String> sendMessage(
    List<ChatMessage> history, {
    required void Function(String delta) onDelta,
  }) async {
    final request = http.Request('POST', Uri.parse('$_baseUrl/v1/chat'))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode({
        'messages': history
            .map((m) => {
                  'role': m.isUser ? 'user' : 'assistant',
                  'content': m.content,
                })
            .toList(),
      });
    if (_appKey.isNotEmpty) {
      request.headers['X-App-Key'] = _appKey;
    }

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw ApiException(response.statusCode, body);
    }

    final buffer = StringBuffer();
    var dataLine = StringBuffer();

    await for (final chunk in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (chunk.startsWith('data:')) {
        dataLine = StringBuffer(chunk.substring(5));
        continue;
      }
      // Continuation of a data line.
      if (dataLine.isNotEmpty && chunk.isNotEmpty) {
        dataLine.write(chunk);
        continue;
      }
      if (dataLine.isNotEmpty) {
        final event = jsonDecode(dataLine.toString()) as Map<String, dynamic>;
        if (event.containsKey('error')) {
          throw ApiException(502, event['error'] as String);
        }
        if (event.containsKey('delta')) {
          final delta = event['delta'] as String;
          buffer.write(delta);
          onDelta(delta);
        }
        dataLine = StringBuffer();
      }
    }
    if (dataLine.isNotEmpty) {
      final event = jsonDecode(dataLine.toString()) as Map<String, dynamic>;
      if (event.containsKey('delta')) {
        final delta = event['delta'] as String;
        buffer.write(delta);
        onDelta(delta);
      }
    }

    return buffer.toString();
  }
}

/// HTTP-layer error surfaced to the UI layer.
class ApiException implements Exception {
  ApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() =>
      'ApiException($statusCode): $body';
}
