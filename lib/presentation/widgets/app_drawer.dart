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
  final Function(String id, String name)?
  onThreadCreated; // 👈 callback báo thread mới

  const AppDrawer({
    super.key,
    required this.onThreadSelected,
    this.onRoleChanged,
    this.onThreadCreated,
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
    await prefs.clear(); // xoá token, user info, thread_id...

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

    // Quay lại màn hình đăng nhập
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "Người dùng";
      userEmail = prefs.getString("user_email") ?? "example@email.com";
      userAvatar = prefs.getString("user_avatar");
    });
  }

  // Nạp threads và cập nhật cache
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

  // Refresh danh sách nhưng vẫn hiển thị cache trong lúc chờ
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
      _renameController.text = ""; // để hiện placeholder "Nhập tên chat"
    });
  }

  Future<void> _submitInlineRename(ThreadModel thread) async {
    final newName = _renameController.text.trim();
    if (newName.isEmpty) {
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

    // Optimistic update: cập nhật ngay tên trong cache và UI
    setState(() {
      if (_cachedThreads != null) {
        _cachedThreads =
            _cachedThreads!
                .map(
                  (t) =>
                      t.id == thread.id
                          ? ThreadModel(
                            id: t.id,
                            name: newName,
                            updatedAt: t.updatedAt,
                          )
                          : t,
                )
                .toList();
      }
      if (_sharedThreadsCache != null) {
        _sharedThreadsCache =
            _sharedThreadsCache!
                .map(
                  (t) =>
                      t.id == thread.id
                          ? ThreadModel(
                            id: t.id,
                            name: newName,
                            updatedAt: t.updatedAt,
                          )
                          : t,
                )
                .toList();
      }
      // Push updated list into FutureBuilder to render immediately
      _threadsFuture = Future.value(_cachedThreads);
      _editingThreadId = null;
      _renameController.clear();
    });
    // làm mới nền để đồng bộ với server nhưng không chặn UI
    _refreshChatList();
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

  Future<void> _selectThread(
    BuildContext context,
    String threadId,
    String threadName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("thread_id", threadId);
    await prefs.setString("thread_name", threadName);

    Navigator.pop(context); // đóng drawer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Đã chọn đoạn chat $threadName",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
      // Đánh dấu là thread mới để ChatScreen hiển thị lời chào mặc định
      await prefs.setBool("thread_is_new", true);
      await prefs.remove("thread_name"); // sẽ auto đặt theo tin nhắn đầu tiên

      // refresh list nhẹ nhàng
      _refreshChatList();

      // đóng Drawer và chuyển qua chat
      if (mounted) {
        Navigator.pop(context);
        widget.onThreadSelected(threadId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Đã tạo cuộc trò chuyện mới",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.blueAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1E1E1E),
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
                    const Expanded(
                      child: Text(
                        "ĐH Y Dược Tp Hồ Chí Minh\nKhoa Răng Hàm Mặt",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),

              // nút tạo thread mới
              ListTile(
                leading: const Icon(Icons.add, color: Colors.white),
                title: const Text(
                  "Tạo đoạn chat mới",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: _createThread,
              ),

              ListTile(
                leading: const Icon(Icons.search, color: Colors.white),
                title: const Text(
                  "Tìm kiếm đoạn chat",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context); // đóng Drawer trước
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.construction,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Tính năng đang được phát triển",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.settings_outlined,
                  color: Colors.white,
                ),
                title: const Text(
                  "Thay đổi vai trò",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleSettingsScreen(),
                    ),
                  );

                  if (changed == true && widget.onRoleChanged != null) {
                    widget.onRoleChanged!(); // callback cho ChatScreen
                  }
                },
              ),

              const Divider(color: Colors.white24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Đoạn Chat",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Danh sách threads từ API
              Expanded(
                child: FutureBuilder<List<ThreadModel>>(
                  future: _threadsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Lỗi: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final threads = snapshot.data ?? _cachedThreads;
                    final showFullLoading =
                        snapshot.connectionState == ConnectionState.waiting &&
                        (threads == null || threads.isEmpty);

                    if (threads == null || threads.isEmpty) {
                      if (showFullLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return const Center(
                        child: Text(
                          "Chưa có đoạn chat",
                          style: TextStyle(color: Colors.white70),
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
                              leading: const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 22,
                              ),
                              title:
                                  isEditing
                                      ? TextField(
                                        controller: _renameController,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          hintText: "Nhập tên chat",
                                          isDense: true,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        onSubmitted:
                                            (_) => _submitInlineRename(thread),
                                      )
                                      : Text(
                                        thread.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              subtitle: null,

                              trailing:
                                  isEditing
                                      ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _editingThreadId = null;
                                                _renameController.clear();
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check,
                                              color: Colors.green,
                                            ),
                                            onPressed:
                                                () =>
                                                    _submitInlineRename(thread),
                                          ),
                                        ],
                                      )
                                      : PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_vert,
                                          color: Colors.white,
                                        ),
                                        color: const Color(0xFFEEF3EB),
                                        onSelected: (value) async {
                                          if (value == "rename") {
                                            _startInlineRename(thread);
                                          } else if (value == "delete") {
                                            final confirm = await showDialog<
                                              bool
                                            >(
                                              context: context,
                                              barrierDismissible: false,
                                              builder:
                                                  (context) => AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    title: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .warning_amber_rounded,
                                                          color:
                                                              Colors
                                                                  .orange
                                                                  .shade600,
                                                          size: 28,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            "Xóa cuộc trò chuyện?",
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    content: const Text(
                                                      "Điều này xóa mất cuộc trò chuyện.",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black87,
                                                      ),
                                                      maxLines: 3,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      softWrap: true,
                                                    ),
                                                    actionsPadding:
                                                        const EdgeInsets.fromLTRB(
                                                          16,
                                                          0,
                                                          16,
                                                          16,
                                                        ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        style: TextButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 24,
                                                                vertical: 12,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          "Hủy",
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      ElevatedButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .red
                                                                  .shade600,
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 24,
                                                                vertical: 12,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          elevation: 2,
                                                        ),
                                                        child: const Text(
                                                          "Xóa",
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );

                                            if (confirm == true) {
                                              final deletedId = thread.id;

                                              // Optimistic update: remove immediately from UI and cache
                                              setState(() {
                                                if (_cachedThreads != null) {
                                                  _cachedThreads =
                                                      _cachedThreads!
                                                          .where(
                                                            (t) =>
                                                                t.id !=
                                                                deletedId,
                                                          )
                                                          .toList();
                                                }
                                                if (_sharedThreadsCache !=
                                                    null) {
                                                  _sharedThreadsCache =
                                                      _sharedThreadsCache!
                                                          .where(
                                                            (t) =>
                                                                t.id !=
                                                                deletedId,
                                                          )
                                                          .toList();
                                                }
                                                // Push updated list into FutureBuilder to render immediately
                                                _threadsFuture = Future.value(
                                                  _cachedThreads,
                                                );
                                              });

                                              // Call API in background, then silently refresh from server
                                              try {
                                                await ThreadApi.deleteThread(
                                                  deletedId,
                                                );
                                                _refreshChatList();
                                              } catch (_) {
                                                // Ignore errors for now as per requirement (no snackbar)
                                              }
                                            }
                                          }
                                        },
                                        itemBuilder:
                                            (context) => [
                                              const PopupMenuItem(
                                                value: "rename",
                                                child: Text("Đổi tên"),
                                              ),
                                              const PopupMenuItem(
                                                value: "delete",
                                                child: Text("Xóa"),
                                              ),
                                            ],
                                      ),
                              onTap:
                                  isEditing
                                      ? null
                                      : () {
                                        _selectThread(
                                          context,
                                          thread.id,
                                          thread.name,
                                        );
                                        widget.onThreadSelected(thread.id);
                                      },
                            );
                          },
                        ),
                        // Spinner overlay removed as requested
                      ],
                    );
                  },
                ),
              ),

              const Divider(color: Colors.white24),

              // User info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          userAvatar != null && userAvatar!.isNotEmpty
                              ? NetworkImage(userAvatar!) // ảnh từ Google/API
                              : const AssetImage(
                                    "assets/avata.jpeg",
                                  ) // fallback
                                  as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userEmail ?? "",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
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
