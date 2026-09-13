import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/chat_service.dart';

/// Holds the conversation state and drives the chat UI.
class ChatController extends ChangeNotifier {
  ChatController({ChatService? service})
      : _service = service ?? ChatService();

  final ChatService _service;

  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  String? _error;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;
  String? get error => _error;

  /// Conversation opened for the first time: show the fixed greeting.
  void ensureGreeting() {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage.assistant(kAssistantGreeting));
      notifyListeners();
    }
  }

  /// Sends [text], streaming the assistant reply into the UI.
  Future<void> send(String text) async {
    if (_isStreaming || text.trim().isEmpty) return;
    final prompt = text.trim();

    _messages.add(ChatMessage.user(prompt));
    // Placeholder assistant bubble that fills up as tokens stream in.
    _messages.add(ChatMessage.assistant(''));
    _isStreaming = true;
    _error = null;
    notifyListeners();

    try {
      // The greeting is display-only: don't send it to the model.
      final history = _messages
          .skip(1) // drop greeting
          .take(_messages.length - 2) // drop the placeholder we just added
          .toList(growable: false);

      await _service.sendMessage(
        history,
        onDelta: (delta) {
          _messages.last = ChatMessage.assistant(
            _messages.last.content + delta,
          );
          notifyListeners();
        },
      );
    } on ApiException catch (e) {
      _error = e.statusCode == 429
          ? 'You are sending messages too quickly. Please wait a moment and '
              'try again.'
          : 'Something went wrong reaching the assistant. '
              'Please check your connection and try again.';
      // Remove the empty placeholder bubble on failure.
      if (_messages.last.isUser == false && _messages.last.content.isEmpty) {
        _messages.removeLast();
      }
      if (kDebugMode) {
        print('ChatService error: $e');
      }
    } finally {
      _isStreaming = false;
      notifyListeners();
    }
  }

  /// Starts a fresh conversation (greeting shown again).
  void reset() {
    _messages.clear();
    _error = null;
    ensureGreeting();
  }
}
