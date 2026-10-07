import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/models/models.dart';
import 'package:nutriguide/services/chat_service.dart';
import 'package:nutriguide/state/chat_controller.dart';

class MockChatService implements ChatService {
  bool shouldThrow = false;
  String mockResponse = 'Mock assistant answer';

  @override
  Future<String> sendMessage(
    List<ChatMessage> history, {
    required void Function(String delta) onDelta,
  }) async {
    if (shouldThrow) {
      throw ApiException(500, 'Server error');
    }
    onDelta(mockResponse);
    return mockResponse;
  }
}

void main() {
  group('ChatController', () {
    late MockChatService mockService;
    late ChatController controller;

    setUp(() {
      mockService = MockChatService();
      controller = ChatController(service: mockService);
    });

    test('ensureGreeting adds fixed greeting when empty', () {
      expect(controller.messages, isEmpty);
      controller.ensureGreeting();
      expect(controller.messages.length, equals(1));
      expect(controller.messages.first.isUser, isFalse);
      expect(controller.messages.first.content, equals(kAssistantGreeting));
    });

    test('send streams response correctly', () async {
      controller.ensureGreeting();
      final future = controller.send('What foods support the liver?');

      expect(controller.isStreaming, isTrue);
      await future;

      expect(controller.isStreaming, isFalse);
      expect(controller.error, isNull);
      expect(controller.messages.length, equals(3)); // Greeting, User, Assistant
      expect(controller.messages[1].content, equals('What foods support the liver?'));
      expect(controller.messages[2].content, equals('Mock assistant answer'));
    });

    test('send handles ApiException gracefully', () async {
      mockService.shouldThrow = true;
      controller.ensureGreeting();

      await controller.send('Test error handling');

      expect(controller.error, isNotNull);
      expect(controller.error, contains('Something went wrong'));
    });

    test('reset clears conversation and restores greeting', () {
      controller.ensureGreeting();
      controller.reset();

      expect(controller.messages.length, equals(1));
      expect(controller.messages.first.content, equals(kAssistantGreeting));
      expect(controller.error, isNull);
    });
  });
}
