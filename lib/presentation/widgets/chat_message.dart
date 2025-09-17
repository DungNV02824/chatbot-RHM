import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isSuggestion;

  final VoidCallback? onTapSuggestion;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,

    this.isSuggestion = false,
    this.onTapSuggestion,
  });

  /// Hàm format lại tin nhắn bot
  String _formatBotMessage(String input) {
    var formatted = input;

    // Thay icon 👉 thành 📌 cho rõ ràng
    formatted = formatted.replaceAll("👉", "\n👉");

    // Đổi "Tóm lại" -> "Kết luận" và xuống dòng
    formatted = formatted.replaceAllMapped(
      RegExp(r"(Tóm lại[:,]?)", caseSensitive: false),
          (match) => "**Tóm lại:**",
    );

    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    if (isSuggestion) {
      // Tin nhắn gợi ý
      return Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onTapSuggestion,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD2E3FC), // xanh nhạt Messenger
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF0084FF), // xanh Messenger đậm
                width: 1,
              ),
            ),
            child: Text(
              "❓ $text", // 👉 thêm icon câu hỏi ở đầu
              style: const TextStyle(
                color: Color(0xFF0084FF), // chữ xanh đậm
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
    }


    // Tin nhắn user / bot
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent.withOpacity(0.8) : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: isUser
            ? Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        )
            : MarkdownBody(
          data: _formatBotMessage(text),
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),
            strong: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
            blockquoteDecoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}
