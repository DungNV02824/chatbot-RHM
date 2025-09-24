import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

class InputField extends StatefulWidget {
  final Function(String) onSend;
  final bool isDarkMode;
  final bool isWaitingForResponse; // 👈 Nhận trạng thái từ parent
  final Function(String id, String name)? onThreadCreated;

  const InputField({
    super.key,
    required this.onSend,
    this.isDarkMode = true,
    this.isWaitingForResponse = false, // 👈 Thêm tham số mới
    this.onThreadCreated,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  final _controller = TextEditingController();

  void _handleSend() async {
    if (_controller.text.trim().isEmpty || widget.isWaitingForResponse) return; // 👈 Sử dụng trạng thái từ parent

    final message = _controller.text.trim();
    _controller.clear();

    widget.onSend(message); // 👈 Chỉ gọi onSend, không quản lý trạng thái ở đây
  }

  Future<void> _createThread() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn chưa đăng nhập!")));
      return;
    }

    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}threads/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"name": "Cuộc trò chuyện mới"}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final threadId = data["id"];
      await prefs.setString("thread_id", threadId);
      await prefs.remove("thread_name");

      if (widget.onThreadCreated != null) {
        widget.onThreadCreated!(threadId, "");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Đã tạo cuộc trò chuyện mới",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.blueAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tạo thread: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDarkMode
        ? Colors.black.withOpacity(0.85)
        : Colors.white.withOpacity(0.9);

    final inputColor = widget.isDarkMode ? Colors.grey[900]! : Colors.grey[200]!;

    final iconColor = widget.isDarkMode ? Colors.white : Colors.black87;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness:
        widget.isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Transform.translate(
          offset: const Offset(0, 8),
          child: Row(
            children: [
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
                    enabled: !widget.isWaitingForResponse, // 👈 Sử dụng từ parent
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: widget.isWaitingForResponse
                          ? "Đang chờ phản hồi..."
                          : "Nhập tin nhắn...",
                      hintStyle: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.white70
                            : Colors.black54,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Nút gửi
              Container(
                decoration: BoxDecoration(
                  color: widget.isWaitingForResponse
                      ? Colors.grey // nút xám khi chờ
                      : (widget.isDarkMode ? Colors.blueAccent : Colors.black),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward, color: Colors.white),
                  onPressed: widget.isWaitingForResponse ? null : _handleSend, // 👈 Sử dụng từ parent
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}