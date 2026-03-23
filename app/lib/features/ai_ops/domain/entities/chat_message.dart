enum MessageType { user, assistant, system }

class ChatMessage {
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, dynamic>? intent;

  ChatMessage({
    required this.text,
    required this.type,
    DateTime? timestamp,
    this.intent,
  }) : this.timestamp = timestamp ?? DateTime.now();
}
