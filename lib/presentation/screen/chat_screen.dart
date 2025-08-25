import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';
import '../widgets/input_field.dart';
import '../widgets/app_drawer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [
    {
      "role": "bot",
      "content": "Xin chào! Tôi là phụ tá AI thông minh của bạn đây. "
          "Xem tôi có thể giúp gì được nào?"
    }
  ];

  bool _isDarkMode = true; // mặc định là dark mode

  void _sendMessage(String text) {
    setState(() {
      _messages.add({"role": "user", "content": text});
      _messages.add({"role": "bot", "content": "Bạn vừa nói: $text"});
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: _isDarkMode ? Colors.white : Colors.black),
        title: Text(
          "RHM Chatbot",
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Nút đăng xuất
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: _isDarkMode ? Colors.white : Colors.black,
              backgroundColor: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text("Đăng xuất"),
          ),
          const SizedBox(width: 8),

          // Nút đổi theme
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: _toggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ChatMessage(
                  text: msg["content"]!,
                  isUser: msg["role"] == "user",
                  // isDarkMode: _isDarkMode, // truyền theme vào
                );
              },
            ),
          ),
          InputField(onSend: _sendMessage, isDarkMode: _isDarkMode),
        ],
      ),
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
    );
  }
}
