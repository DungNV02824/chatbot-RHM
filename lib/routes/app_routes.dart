import 'package:flutter/material.dart';
import 'package:chatbot/presentation/screen/login_screen.dart';
import 'package:chatbot/presentation/screen/chat_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String chat = '/chat';

  static Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginScreen(),
    chat: (_) => const ChatScreen(),
  };
}
