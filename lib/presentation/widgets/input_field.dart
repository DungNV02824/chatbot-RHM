import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
class InputField extends StatefulWidget {
  final Function(String) onSend;
  final bool isDarkMode;
  final Function(String id, String name)? onThreadCreated; // 👈 thêm callback

  const InputField({
    super.key,
    required this.onSend,
    this.isDarkMode = true,
    this.onThreadCreated,
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

  Future<void> _createThread() async {
    final threadNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // bo góc dialog
        ),
        title: Row(
          children: const [
            Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              "Tạo cuộc trò chuyện",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: threadNameController,
          decoration: InputDecoration(
            hintText: "Nhập tên chat",
            prefixIcon: const Icon(Icons.edit, color: Colors.blueAccent),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.redAccent),
            label: const Text(
              "Hủy",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () async {
              final name = threadNameController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Vui lòng nhập tên cuộc trò chuyện",
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return; // dừng lại, không gọi API
              }

              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString("auth_token");

              if (token == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bạn chưa đăng nhập!")),
                );
                return;
              }

              final response = await http.post(
                Uri.parse("${AppConstants.baseUrl}threads/"),
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer $token",
                },
                body: jsonEncode({
                  "name": name, // dùng biến name đã trim
                }),
              );

              Navigator.pop(context); // đóng dialog trước

              if (response.statusCode == 201) {
                final data = jsonDecode(response.body);
                final threadId = data["id"];
                final threadName = data["name"];

                await prefs.setString("thread_id", threadId);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Tạo cuộc trò chuyện thành công",
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                );

                if (widget.onThreadCreated != null) {
                  widget.onThreadCreated!(threadId, threadName);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi tạo thread: ${response.body}")),
                );
              }
            },

            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              "Tạo",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDarkMode
        ? Colors.black.withOpacity(0.85)
        : Colors.white.withOpacity(0.9);

    final inputColor = widget.isDarkMode ? Colors.grey[900]! : Colors.grey[200]!;

    final iconColor = widget.isDarkMode ? Colors.white : Colors.black87;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: backgroundColor,
      systemNavigationBarIconBrightness:
      widget.isDarkMode ? Brightness.light : Brightness.dark,
    ));

    return Container(
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
      child: SafeArea(
        top: false,
        child: Transform.translate(
          offset: const Offset(0, 8),
          child: Row(
            children: [
              // Nút "+"
              Material(
                color: inputColor,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: Icon(Icons.add, color: iconColor),
                  onPressed: _createThread,
                ),
              ),
              const SizedBox(width: 8),

              // Ô nhập
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: inputColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Nhập tin nhắn...",
                      hintStyle: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.white70
                            : Colors.black54,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Nút gửi
              Container(
                decoration: BoxDecoration(
                  color:
                  widget.isDarkMode ? Colors.blueAccent : Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
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
      ),
    );
  }
}
