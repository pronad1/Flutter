import 'package:flutter/material.dart';
import 'floating_chatbot_button.dart';

/// Wraps any screen with the floating chatbot
/// Use this to add the chatbot to all your main screens
class ChatbotWrapper extends StatelessWidget {
  final Widget child;
  final bool showChatbot;

  const ChatbotWrapper({
    super.key,
    required this.child,
    this.showChatbot = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showChatbot) return child;

    return Stack(
      children: [
        child,
        const FloatingChatbotButton(),
      ],
    );
  }
}
