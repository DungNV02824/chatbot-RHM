import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';
import '../widgets/input_field.dart';
import '../widgets/app_drawer.dart';
import '../../data/api/chat_api.dart'; // Import API
import '../widgets/typing_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [
    {
      "role": "bot",
      "content":
          "Xin chào 😊! Tôi là trợ lý AI của bạn đây. Rất vui được hỗ trợ bạn - Bạn cần tôi giúp gì hôm nay?",
    },
  ];

  String? _currentRole;
  bool _isDarkMode = true;
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRole();
    _checkIfNewThreadAndShowGreeting();
  }

  Future<void> _checkIfNewThreadAndShowGreeting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isNew = prefs.getBool("thread_is_new") ?? false;
      if (!isNew) return;

      // Reset flag so it only shows once
      await prefs.setBool("thread_is_new", false);

      setState(() {
        _messages.clear();
        _messages.add({
          "role": "bot",
          "content":
              "Xin chào 😊! Tôi là trợ lý AI của bạn đây. Rất vui được hỗ trợ bạn - Bạn cần tôi giúp gì hôm nay?",
        });
      });
    } catch (_) {}
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();

    // Nếu chưa có key thì gán mặc định
    if (!prefs.containsKey("selected_role_name")) {
      await prefs.setString("selected_role_id", "doctor_endocrine"); // id cứng
      await prefs.setString("selected_role_name", "Bác sĩ Nội tiết"); // tên hiển thị
    }

    final role = prefs.getString("selected_role_name") ?? "Chưa chọn vai trò";

    debugPrint("👉 Role hiện tại: $role");

    setState(() {
      _currentRole = role;
    });
  }


  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isTyping = true; // bot bắt đầu gõ
    });
    _scrollToBottom(); // cuộn xuống cuối

    // Nếu là tin nhắn đầu tiên sau khi tạo thread mới, auto đặt tên thread
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentName = prefs.getString("thread_name");
      final threadId = prefs.getString("thread_id");
      if (threadId != null && (currentName == null || currentName.isEmpty)) {
        final autoName = text.trim().split(" ").take(8).join(" ");
        // Lưu tên để hiển thị về sau; API rename để đồng bộ backend nếu có endpoint
        await prefs.setString("thread_name", autoName);
      }
    } catch (_) {}

    try {
      final response = await ChatApi.sendMessage(text);

      final explanation =
          response["explanation"] ??
          response["summary"] ??
          "Không có phản hồi từ bot";

      final List<dynamic>? questionSuggestion = response["questionSuggestion"];

      setState(() {
        _isTyping = false;

        // Thêm nội dung trả lời bot
        _messages.add({"role": "bot", "type": "text", "content": explanation});

        // Nếu có gợi ý câu hỏi, thêm vào dưới dạng suggestion
        if (questionSuggestion != null && questionSuggestion.isNotEmpty) {
          // Thêm tin nhắn giới thiệu
          _messages.add({
            "role": "bot",
            "type": "text",
            "content": "💡 Mình gợi ý bạn một số câu hỏi nhé:",
          });

          for (var suggestion in questionSuggestion) {
            _messages.add({
              "role": "bot",
              "type": "suggestion",
              "content": suggestion,
            });
          }
        }
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({"role": "bot", "content": "Lỗi kết nối API: $e"});
      });
    } finally {
      // Cleanup if needed
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: AppDrawer(
        onThreadSelected: (threadId) async {
          setState(() {
            _messages.clear();
          });

          try {
            final response = await ChatApi.getThreadDetail(threadId);

            setState(() {
              _messages.addAll(
                response.map(
                  (msg) => {"role": msg["role"], "content": msg["content"]},
                ),
              );
            });
          } catch (e) {
            setState(() {
              _messages.add({
                "role": "bot",
                "content": "Lỗi khi tải đoạn chat: $e",
              });
            });
          } finally {
            // Thread loaded
          }
        },
        onRoleChanged: _loadRole,
      ),

      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        iconTheme: IconThemeData(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
        title: Text(
          "RHM Chatbot",
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _currentRole ?? "Chưa chọn vai trò",
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg.jpg"),
            fit: BoxFit.cover, // phủ toàn màn hình
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return const TypingIndicator(); // hiển thị typing ở cuối
                  }
                  final msg = _messages[index];
                  return ChatMessage(
                    text: msg["content"]!,
                    isUser: msg["role"] == "user",
                    isSuggestion: msg["type"] == "suggestion",
                    onTapSuggestion:
                        msg["type"] == "suggestion"
                            ? () => _sendMessage(msg["content"]!)
                            : null,
                  );
                },
              ),
            ),

            // if (_isLoading) const LinearProgressIndicator(),
            InputField(
              onSend: _sendMessage,
              isDarkMode: _isDarkMode,
              onThreadCreated: (id, name) {
                setState(() {
                  // Xóa tin nhắn cũ và reset với lời chào ban đầu
                  _messages.clear();
                  _messages.add({
                    "role": "bot",
                    "content":
                        "Xin chào 😊! Tôi là trợ lý AI của bạn. Rất vui được hỗ trợ bạn - Bạn cần tôi giúp gì hôm nay?",
                  });
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
