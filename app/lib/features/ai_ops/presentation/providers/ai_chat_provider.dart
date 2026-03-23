import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/chat_message.dart';


class AiChatProvider with ChangeNotifier {
  final ApiClient apiClient;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  AiChatProvider({required this.apiClient}) {
    // Initial greeting
    _messages.add(ChatMessage(
      text: "Hello! I'm your DevOps Assistant. How can I help you today?",
      type: MessageType.assistant,
    ));
  }

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    _messages.add(ChatMessage(text: text, type: MessageType.user));
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post('/api/v1/ai/process', data: {
        'query': text,
        'context': {}, // Can add more context here later
      });

      final answer = response['answer'] as String;
      final intent = response['intent'] as Map<String, dynamic>?;

      _messages.add(ChatMessage(
        text: answer,
        type: MessageType.assistant,
        intent: intent,
      ));
    } catch (e) {
      _messages.add(ChatMessage(
        text: "Error: Failed to get response from AI assistant. ${e.toString()}",
        type: MessageType.system,
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> executeIntent(Map<String, dynamic> intent) async {
    _messages.add(ChatMessage(
      text: "Executing command: ${intent['intent']}...",
      type: MessageType.system,
    ));
    notifyListeners();

    try {
      final response = await apiClient.post('/api/v1/guardian/execute', data: {'intent': intent});


      
      final bool rejected = response['status'] == 'rejected';
      
      _messages.add(ChatMessage(
        text: rejected 
          ? "Command Rejected: ${response['reason']}\nSuggestion: ${response['suggestion']}" 
          : "Command executed successfully: ${response['message']}",
        type: rejected ? MessageType.system : MessageType.assistant,
      ));
    } catch (e) {
      _messages.add(ChatMessage(
        text: "Execution failed: ${e.toString()}",
        type: MessageType.system,
      ));
    } finally {
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    _messages.add(ChatMessage(
      text: "Chat cleared. How can I help you today?",
      type: MessageType.assistant,
    ));
    notifyListeners();
  }
}
