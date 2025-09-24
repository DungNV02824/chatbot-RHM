import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';
import '../widgets/input_field.dart';
import '../widgets/app_drawer.dart';
import '../../data/api/chat_api.dart';
import '../../data/api/ThreadApi.dart';
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
  String? _currentThreadName;
  bool _isDarkMode = true;
  bool _isTyping = false;
  bool _isWaitingForResponse = false; // 👈 Thêm biến này để theo dõi trạng thái
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
    _loadThreadName();
    _checkIfNewThreadAndShowGreeting();
  }

  Future<void> _checkIfNewThreadAndShowGreeting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isNew = prefs.getBool("thread_is_new") ?? false;
      if (!isNew) return;

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

    if (!prefs.containsKey("selected_role_name")) {
      await prefs.setString("selected_role_id", "doctor_endocrine");
      await prefs.setString(
        "selected_role_name",
        "Bác sĩ Nội tiết",
      );
    }

    final role = prefs.getString("selected_role_name") ?? "Chưa chọn vai trò";

    setState(() {
      _currentRole = role;
    });
  }

  Future<void> _loadThreadName() async {
    final prefs = await SharedPreferences.getInstance();
    final threadName = prefs.getString("thread_name");

    setState(() {
      _currentThreadName = threadName;
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_isWaitingForResponse) return; // 👈 Chặn nếu đang chờ phản hồi

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isTyping = true;
      _isWaitingForResponse = true; // 👈 Bắt đầu chờ phản hồi
    });
    _scrollToBottom();

    await _autoRenameThreadIfNeeded(text);

    try {
      final response = await ChatApi.sendMessage(text);

      final explanation =
          response["explanation"] ??
              response["summary"] ??
              "Không có phản hồi từ bot";

      final List<dynamic>? questionSuggestion = response["questionSuggestion"];

      setState(() {
        _isTyping = false;
        _isWaitingForResponse = false; // 👈 Kết thúc chờ phản hồi

        _messages.add({"role": "bot", "type": "text", "content": explanation});

        if (questionSuggestion != null && questionSuggestion.isNotEmpty) {
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
        _isTyping = false;
        _isWaitingForResponse = false; // 👈 Kết thúc chờ ngay cả khi có lỗi
        _messages.add({"role": "bot", "content": "Lỗi kết nối API: $e"});
      });
    }
  }

  // 👈 Thêm hàm xử lý khi click vào gợi ý
  void _onSuggestionTap(String suggestion) {
    if (!_isWaitingForResponse) {
      _sendMessage(suggestion);
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  Future<void> _autoRenameThreadIfNeeded(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentName = prefs.getString("thread_name");
      final threadId = prefs.getString("thread_id");

      if (threadId != null &&
          (currentName == null ||
              currentName.isEmpty ||
              currentName == "Cuộc trò chuyện mới")) {
        final words = message.trim().split(RegExp(r'\s+'));
        final autoName = words.take(8).join(" ");
        final finalName =
        autoName.length > 50 ? "${autoName.substring(0, 47)}..." : autoName;

        await prefs.setString("thread_name", finalName);

        setState(() {
          _currentThreadName = finalName;
        });

        ThreadApi.renameThread(threadId, finalName).catchError((error) {
          print("Lỗi khi đồng bộ tên thread với backend: $error");
        });
      }
    } catch (e) {
      print("Lỗi khi auto rename thread: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: AppDrawer(
        isDarkMode: _isDarkMode,
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

            _loadThreadName();
          } catch (e) {
            setState(() {
              _messages.add({
                "role": "bot",
                "content": "Lỗi khi tải đoạn chat: $e",
              });
            });
          }
        },
        onRoleChanged: _loadRole,
      ),

      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        iconTheme: IconThemeData(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "RHM Chatbot",
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _currentRole ?? "Chưa chọn vai trò",
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: _isDarkMode ? Colors.yellow : Colors.orange,
            ),
            onPressed: _toggleTheme,
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg.jpg"),
            fit: BoxFit.cover,
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
                    return const TypingIndicator();
                  }
                  final msg = _messages[index];
                  return ChatMessage(
                    text: msg["content"]!,
                    isUser: msg["role"] == "user",
                    isSuggestion: msg["type"] == "suggestion",
                    onTapSuggestion: msg["type"] == "suggestion" && !_isWaitingForResponse // 👈 Chỉ cho phép tap khi không chờ phản hồi
                        ? () => _onSuggestionTap(msg["content"]!)
                        : null,
                  );
                },
              ),
            ),

            InputField(
              onSend: _sendMessage,
              isDarkMode: _isDarkMode,
              isWaitingForResponse: _isWaitingForResponse, // 👈 Truyền trạng thái xuống
              onThreadCreated: (id, name) {
                setState(() {
                  _messages.clear();
                  _messages.add({
                    "role": "bot",
                    "content":
                    "Xin chào 😊! Tôi là trợ lý AI của bạn. Rất vui được hỗ trợ bạn - Bạn cần tôi giúp gì hôm nay?",
                  });
                  _currentThreadName = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}