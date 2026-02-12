
import 'package:flutter/material.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../providers/chat_providers.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isUser ? AppTheme.primary.withOpacity(0.2) : AppTheme.glassBackground;
    final textColor = isUser ? AppTheme.primary : Colors.white;

    return Column(
      crossAxisAlignment: align,
      children: [
        if (message.imageUrl != null)
           Padding(
             padding: const EdgeInsets.only(bottom: 8.0),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(12),
               child: Image.network(message.imageUrl!, height: 150, fit: BoxFit.cover),
             ),
           ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
              bottomRight: isUser ? Radius.zero : const Radius.circular(16),
            ),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Text(
            message.content,
            style: TextStyle(color: textColor, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
