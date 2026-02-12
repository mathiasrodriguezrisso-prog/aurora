import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora_app/core/config/env_config.dart';

// 1. Message Model
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final String? imageUrl;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    this.imageUrl,
    required this.timestamp,
  });
}

// 2. Chat Messages Provider
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier();
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super([
    ChatMessage(
      id: 'welcome',
      content: "Hi! I'm Dr. Aurora, your AI grow assistant. Ask me anything about your grow! 🌱",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  Future<void> sendMessage(String text, {String? imagePath}) async {
    // 1. Add user message
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      imageUrl: imagePath,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];

    // 2. Try backend
    try {
      final dio = Dio(BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }

      final response = await dio.post('/chat/message', data: {
        'message': text,
        'image_path': imagePath,
      });

      final responseText = response.data['response']?.toString()
          ?? response.data['message']?.toString()
          ?? "I received your message but couldn't generate a response.";

      state = [...state, ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      )];
    } catch (e) {
      // 3. Fallback message
      state = [...state, ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: "I'm currently offline. Please make sure the Aurora backend is running on ${EnvConfig.apiBaseUrl}. In the meantime, check the Knowledge Base in the grow section for guidance. 🔧",
        isUser: false,
        timestamp: DateTime.now(),
      )];
    }
  }
}
