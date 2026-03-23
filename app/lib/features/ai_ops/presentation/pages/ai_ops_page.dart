import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_chat_provider.dart';
import '../../domain/entities/chat_message.dart';

import 'package:intl/intl.dart';

class AiOpsPage extends StatefulWidget {
  const AiOpsPage({super.key});

  @override
  State<AiOpsPage> createState() => _AiOpsPageState();
}

class _AiOpsPageState extends State<AiOpsPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<AiChatProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.blueAccent),
                const SizedBox(width: 12),
                const Text(
                  'AI Operations Center',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => chatProvider.clearMessages(),
                  tooltip: 'Clear History',
                ),
              ],
            ),
          ),

          // Chat Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                final message = chatProvider.messages[index];
                return _ChatMessageWidget(
                  message: message,
                  onExecute: message.intent != null
                      ? () => chatProvider.executeIntent(message.intent!)
                      : null,
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask Agent-1 or issue a command...',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (val) {
                      chatProvider.sendMessage(val);
                      _controller.clear();
                      _scrollToBottom();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: chatProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: chatProvider.isLoading
                        ? null
                        : () {
                            chatProvider.sendMessage(_controller.text);
                            _controller.clear();
                            _scrollToBottom();
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onExecute;

  const _ChatMessageWidget({required this.message, this.onExecute});

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.type == MessageType.assistant;
    final isSystem = message.type == MessageType.system;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAssistant || isSystem ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAssistant || isSystem)
            CircleAvatar(
              radius: 16,
              backgroundColor: isSystem ? Colors.orange.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
              child: Icon(
                isSystem ? Icons.warning_amber : Icons.psychology,
                size: 16,
                color: isSystem ? Colors.orange : Colors.blueAccent,
              ),
            ),
          if (isAssistant || isSystem) const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: isAssistant || isSystem ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAssistant
                        ? Colors.white.withOpacity(0.08)
                        : isSystem
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      topLeft: isAssistant || isSystem ? Radius.zero : null,
                      bottomRight: !isAssistant && !isSystem ? Radius.zero : null,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isSystem ? Colors.orange[200] : Colors.white.withOpacity(0.9),
                        ),
                      ),
                      if (message.intent != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deteched Intent:',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              Text(
                                '${message.intent!['intent']} in ${message.intent!['namespace'] ?? 'default'}',
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: onExecute,
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Execute Action'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.2),
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (!isAssistant && !isSystem) const SizedBox(width: 12),
          if (!isAssistant && !isSystem)
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
