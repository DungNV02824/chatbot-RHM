import 'package:flutter/material.dart';

class InputField extends StatefulWidget {
  final Function(String) onSend;
  final bool isDarkMode;

  const InputField({
    super.key,
    required this.onSend,
    this.isDarkMode = true,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  final _controller = TextEditingController();

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;
    widget.onSend(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final inputColor = widget.isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade200;
    final iconColor = widget.isDarkMode ? Colors.white70 : Colors.black87;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: Row(
          children: [
            // Nút "+"
            Material(
              color: inputColor,
              shape: const CircleBorder(),
              child: IconButton(
                icon: Icon(Icons.add, color: iconColor),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),

            // Ô nhập + viền bo tròn
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: inputColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: "Nhập tin nhắn...",
                    hintStyle: TextStyle(
                      color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Nút voice
            Material(
              color: inputColor,
              shape: const CircleBorder(),
              // child: IconButton(
              //   icon: Icon(Icons.mic, color: iconColor),
              //   onPressed: () {},
              // ),
            ),
            const SizedBox(width: 6),

            // Nút gửi (nổi bật hơn)
            Container(
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.blueAccent : Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward, color: Colors.white),
                onPressed: _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
