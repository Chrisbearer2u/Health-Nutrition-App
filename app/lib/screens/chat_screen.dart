import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../state/chat_controller.dart';
import '../widgets/disclaimer_banner.dart';

/// Section (b): the AI assistant chat. Opens with the fixed greeting message,
/// then answers disease/nutrition questions with streamed responses.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();
    await context.read<ChatController>().send(text);
    _autoScroll();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    _autoScroll();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Assistant'),
        actions: [
          IconButton(
            tooltip: 'New conversation',
            icon: const Icon(Icons.refresh),
            onPressed: controller.isStreaming ? null : controller.reset,
          ),
        ],
      ),
      body: Column(
        children: [
          if (controller.error != null)
            Material(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: scheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.error!,
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: controller.messages.length,
              itemBuilder: (context, i) {
                final message = controller.messages[i];
                final isUser = message.isUser;
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.82,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: isUser
                        ? Text(
                            message.content,
                            style:
                                TextStyle(color: scheme.onPrimary),
                          )
                        : MarkdownBody(
                            data: message.content.isEmpty &&
                                    controller.isStreaming &&
                                    i ==
                                        controller.messages.length - 1
                                ? '…'
                                : message.content,
                            styleSheet: MarkdownStyleSheet.fromTheme(
                                    Theme.of(context))
                                .copyWith(
                              p: TextStyle(
                                  color: scheme.onSurface, fontSize: 14),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          const DisclaimerBanner(compact: true),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      enabled: !controller.isStreaming,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask about a disease…',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: controller.isStreaming ? null : _send,
                    icon: controller.isStreaming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
