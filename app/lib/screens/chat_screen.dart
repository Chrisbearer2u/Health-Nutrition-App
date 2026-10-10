import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../state/chat_controller.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/theme_toggle_button.dart';

/// Section (b): the AI assistant chat with suggested prompts, themed message bubbles,
/// and streaming responses.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  static const List<String> _suggestedPrompts = [
    'What foods support liver function?',
    'Natural foods for Type 2 Diabetes',
    'Supplements for heart health',
    'Foods that boost kidney health',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatController>().ensureGreeting();
      }
    });
  }

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

  Future<void> _send([String? textOverride]) async {
    final text = textOverride ?? _inputController.text;
    if (text.trim().isEmpty) return;
    if (textOverride == null) {
      _inputController.clear();
    }
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
        title: Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: scheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Health Assistant'),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'New conversation',
            icon: const Icon(Icons.refresh),
            onPressed: controller.isStreaming ? null : () => _confirmReset(context),
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
                    Icon(Icons.error_outline, color: scheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.error!,
                        style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: controller.messages.length,
              itemBuilder: (context, i) {
                final message = controller.messages[i];
                final isUser = message.isUser;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment:
                        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(
                            Icons.health_and_safety,
                            size: 18,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isUser ? 18 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 18),
                            ),
                          ),
                          child: isUser
                              ? Text(
                                  message.content,
                                  style: TextStyle(
                                    color: scheme.onPrimary,
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                )
                              : MarkdownBody(
                                  data: message.content.isEmpty &&
                                          controller.isStreaming &&
                                          i == controller.messages.length - 1
                                      ? '⚡ Generating health guidance…'
                                      : message.content,
                                  styleSheet: MarkdownStyleSheet.fromTheme(
                                          Theme.of(context))
                                      .copyWith(
                                    p: TextStyle(
                                      color: scheme.onSurface,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: scheme.secondaryContainer,
                          child: Icon(
                            Icons.person,
                            size: 18,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Quick Suggested Prompts (visible if conversation has only 1 message, i.e., greeting)
          if (controller.messages.length <= 1 && !controller.isStreaming)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: _suggestedPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(Icons.tips_and_updates_outlined,
                          size: 16, color: scheme.primary),
                      label: Text(
                        prompt,
                        style: TextStyle(fontSize: 12, color: scheme.onSurface),
                      ),
                      onPressed: () => _send(prompt),
                    ),
                  );
                }).toList(),
              ),
            ),

          const DisclaimerBanner(compact: true),

          // Input Bar
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
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
                      decoration: InputDecoration(
                        hintText: 'Ask about a disease or nutrition…',
                        prefixIcon: Icon(Icons.chat_bubble_outline,
                            size: 20, color: scheme.primary),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: controller.isStreaming ? null : () => _send(),
                    icon: controller.isStreaming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Conversation?'),
        content: const Text('This will clear current chat messages and start fresh.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ChatController>().reset();
            },
            child: const Text('Start New'),
          ),
        ],
      ),
    );
  }
}
