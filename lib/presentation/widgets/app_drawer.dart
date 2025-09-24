import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../data/api/ThreadApi.dart';
import '../../models/ThreadModel.dart';
import '../screen/RoleSettingsScreen.dart';
import 'package:chatbot/routes/app_routes.dart';
import '../../core/constants.dart';

class AppDrawer extends StatefulWidget {
  final Function(String) onThreadSelected;
  final VoidCallback? onRoleChanged;
  final Function(String id, String name)? onThreadCreated;
  final bool isDarkMode;
  final VoidCallback? onToggleTheme;

  const AppDrawer({
    super.key,
    required this.onThreadSelected,
    this.onRoleChanged,
    this.onThreadCreated,
    required this.isDarkMode,
    this.onToggleTheme,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? userName;
  String? userEmail;
  String? userAvatar;
  List<ThreadModel>? _cachedThreads;
  Future<List<ThreadModel>>? _threadsFuture;
  static List<ThreadModel>? _sharedThreadsCache;
  bool _isRefreshing = false;
  String? _editingThreadId;
  final TextEditingController _renameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    if (_sharedThreadsCache != null) {
      _cachedThreads = _sharedThreadsCache;
      _threadsFuture = Future.value(_cachedThreads);
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshChatList());
    } else {
      _threadsFuture = _loadThreads();
    }
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.logout, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text(
              "Đã đăng xuất",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "Người dùng";
      userEmail = prefs.getString("user_email") ?? "example@email.com";
      userAvatar = prefs.getString("user_avatar");
    });
  }

  Future<List<ThreadModel>> _loadThreads() async {
    final threads = await ThreadApi.fetchThreads();
    if (mounted) {
      setState(() {
        _cachedThreads = threads;
        _sharedThreadsCache = threads;
      });
    }
    return threads;
  }

  void _refreshChatList() {
    if (_isRefreshing) return;
    _isRefreshing = true;
    ThreadApi.fetchThreads()
        .then((threads) {
      if (!mounted) return;
      setState(() {
        _cachedThreads = threads;
        _sharedThreadsCache = threads;
        _isRefreshing = false;
      });
    })
        .catchError((_) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
      });
    });
  }

  void _startInlineRename(ThreadModel thread) {
    setState(() {
      _editingThreadId = thread.id;
      _renameController.text = thread.name; // Pre-fill with current name
    });
  }

  Future<void> _submitInlineRename(ThreadModel thread) async {
    final newName = _renameController.text.trim();
    if (newName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text(
                "Vui lòng nhập tên chat",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    await ThreadApi.renameThread(thread.id, newName);

    if (!mounted) return;

    // Optimistic update
    setState(() {
      if (_cachedThreads != null) {
        _cachedThreads = _cachedThreads!.map((t) => t.id == thread.id
            ? ThreadModel(id: t.id, name: newName, updatedAt: t.updatedAt)
            : t).toList();
      }
      if (_sharedThreadsCache != null) {
        _sharedThreadsCache = _sharedThreadsCache!.map((t) => t.id == thread.id
            ? ThreadModel(id: t.id, name: newName, updatedAt: t.updatedAt)
            : t).toList();
      }
      _threadsFuture = Future.value(_cachedThreads);
      _editingThreadId = null;
      _renameController.clear();
    });

    _refreshChatList();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text(
              "Đổi tên thành công",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _selectThread(BuildContext context, String threadId, String threadName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("thread_id", threadId);
    await prefs.setString("thread_name", threadName);

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Đã chọn đoạn chat $threadName",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _createThread() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text(
                "Bạn chưa đăng nhập!",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
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
      await prefs.setBool("thread_is_new", true);
      await prefs.remove("thread_name");

      _refreshChatList();

      if (mounted) {
        Navigator.pop(context);
        widget.onThreadSelected(threadId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Đã tạo cuộc trò chuyện mới",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.blueAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Lỗi tạo thread",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = widget.isDarkMode ? Colors.white70 : Colors.black54;
    final iconColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final dividerColor = widget.isDarkMode ? Colors.white24 : Colors.grey.shade300;

    return Drawer(
      child: Container(
        color: bgColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage("assets/logo_yd.png"),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "ĐH Y Dược Tp Hồ Chí Minh\nKhoa Răng Hàm Mặt",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: dividerColor),

              // Menu items
              ListTile(
                leading: Icon(Icons.add, color: iconColor),
                title: Text("Tạo đoạn chat mới", style: TextStyle(color: textColor)),
                onTap: _createThread,
              ),

              ListTile(
                leading: Icon(Icons.search, color: iconColor),
                title: Text("Tìm kiếm đoạn chat", style: TextStyle(color: textColor)),
                onTap: () {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.construction, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            "Tính năng đang được phát triển",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.orange.shade600,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),

              ListTile(
                leading: Icon(Icons.settings_outlined, color: iconColor),
                title: Text("Thay đổi vai trò", style: TextStyle(color: textColor)),
                onTap: () async {
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoleSettingsScreen()),
                  );

                  if (changed == true && widget.onRoleChanged != null) {
                    widget.onRoleChanged!();
                  }
                },
              ),

              Divider(color: dividerColor),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Đoạn Chat",
                  style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold),
                ),
              ),

              // Threads list
              Expanded(
                child: FutureBuilder<List<ThreadModel>>(
                  future: _threadsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Lỗi: ${snapshot.error}",
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final threads = snapshot.data ?? _cachedThreads;
                    final showFullLoading = snapshot.connectionState == ConnectionState.waiting &&
                        (threads == null || threads.isEmpty);

                    if (threads == null || threads.isEmpty) {
                      if (showFullLoading) {
                        return Center(child: CircularProgressIndicator(color: iconColor));
                      }
                      return Center(
                        child: Text(
                          "Chưa có đoạn chat",
                          style: TextStyle(color: subTextColor),
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        ListView.builder(
                          itemCount: threads.length,
                          itemBuilder: (context, index) {
                            final thread = threads[index];
                            final isEditing = _editingThreadId == thread.id;
                            return ListTile(
                              leading: Icon(
                                Icons.chat_bubble_outline,
                                color: iconColor,
                                size: 22,
                              ),
                              title: isEditing
                                  ? TextField(
                                controller: _renameController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: "Nhập tên chat",
                                  hintStyle: TextStyle(color: subTextColor),
                                  isDense: true,
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: iconColor),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: iconColor),
                                  ),
                                ),
                                style: TextStyle(color: textColor),
                                onSubmitted: (_) => _submitInlineRename(thread),
                              )
                                  : Text(
                                thread.name,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isEditing
                                  ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.close, color: Colors.redAccent),
                                    onPressed: () {
                                      setState(() {
                                        _editingThreadId = null;
                                        _renameController.clear();
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _submitInlineRename(thread),
                                  ),
                                ],
                              )
                                  : PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, color: iconColor),
                                color: widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFEEF3EB),
                                onSelected: (value) async {
                                  if (value == "rename") {
                                    _startInlineRename(thread);
                                  } else if (value == "delete") {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        backgroundColor: widget.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                                        title: Row(
                                          children: [
                                            Icon(Icons.warning_amber_rounded,
                                                color: Colors.orange.shade600, size: 28),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                "Xóa cuộc trò chuyện?",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: Text(
                                          "Điều này xóa mất cuộc trò chuyện.",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),
                                        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: Text(
                                              "Hủy",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: subTextColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red.shade600,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              elevation: 2,
                                            ),
                                            child: const Text(
                                              "Xóa",
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      final deletedId = thread.id;

                                      setState(() {
                                        if (_cachedThreads != null) {
                                          _cachedThreads = _cachedThreads!.where((t) => t.id != deletedId).toList();
                                        }
                                        if (_sharedThreadsCache != null) {
                                          _sharedThreadsCache = _sharedThreadsCache!.where((t) => t.id != deletedId).toList();
                                        }
                                        _threadsFuture = Future.value(_cachedThreads);
                                      });

                                      try {
                                        await ThreadApi.deleteThread(deletedId);
                                        _refreshChatList();
                                      } catch (_) {
                                        // Ignore errors
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: "rename",
                                    child: Text("Đổi tên", style: TextStyle(color: textColor)),
                                  ),
                                  PopupMenuItem(
                                    value: "delete",
                                    child: Text("Xóa", style: TextStyle(color: textColor)),
                                  ),
                                ],
                              ),
                              onTap: isEditing ? null : () {
                                _selectThread(context, thread.id, thread.name);
                                widget.onThreadSelected(thread.id);
                              },
                            );
                          },
                        ),
                        if (_isRefreshing)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: bgColor.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              Divider(color: dividerColor),

              // User info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: userAvatar != null && userAvatar!.isNotEmpty
                          ? NetworkImage(userAvatar!)
                          : const AssetImage("assets/avata.jpeg") as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName ?? "",
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          Text(userEmail ?? "",
                              style: TextStyle(color: subTextColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: dividerColor),

              ListTile(
                leading: Icon(Icons.logout, color: Colors.redAccent),
                title: Text(
                  "Đăng xuất",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}