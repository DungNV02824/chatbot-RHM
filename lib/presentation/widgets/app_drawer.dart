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
  final Function(String id, String name)? onThreadCreated; // 👈 callback báo thread mới

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

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // await prefs.clear(); // xoá token, user info, thread_id...

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã đăng xuất"),
        backgroundColor: Colors.redAccent, // 👈 đổi màu nền
        behavior: SnackBarBehavior.floating, // 👈 nổi trên nội dung
        duration: Duration(seconds: 2), // 👈 thời gian hiển thị
      ),
    );


    // Quay lại màn hình đăng nhập
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
          (route) => false,
    );
  }



  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? "Người dùng";
      userEmail = prefs.getString("user_email") ?? "example@email.com";
      userAvatar = prefs.getString("user_avatar");
    });
  }


  Future<void> _selectThread(BuildContext context, String threadId,String threadName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("thread_id", threadId);
    await prefs.setString("thread_name", threadName);

    Navigator.pop(context); // đóng drawer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Đã chọn đoạn chat $threadName",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent, // 👈 đổi màu nền
        behavior: SnackBarBehavior.floating, // 👈 cho nó nổi (tùy chọn)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 👈 bo góc
        ),
        margin: const EdgeInsets.all(12), // 👈 đặt margin
        duration: const Duration(seconds: 2), // 👈 thời gian hiển thị
      ),
    );

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

              // ✅ Kiểm tra trống
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
                return; // dừng, không gọi API
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
                  "name": name, // dùng biến đã trim
                }),
              );

              Navigator.pop(context); // đóng dialog sau khi gọi API

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
                title: const Text("Tạo đoạn chat mới",
                    style: TextStyle(color: Colors.white)),
                onTap: _createThread,
              ),

              ListTile(
                leading: const Icon(Icons.search, color: Colors.white),
                title: const Text("Tìm kiếm đoạn chat",
                    style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined,
                    color: Colors.white),
                title: const Text("Thay đổi vai trò",
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RoleSettingsScreen()),
                  );

                  if (changed == true && widget.onRoleChanged != null) {
                    widget.onRoleChanged!(); // callback cho ChatScreen
                  }
                },
              ),

              const Divider(color: Colors.white24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("Đoạn Chat",
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold)),
              ),

              // Danh sách threads từ API
              Expanded(
                child: FutureBuilder<List<ThreadModel>>(
                  future: ThreadApi.fetchThreads(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text("Lỗi: ${snapshot.error}",
                              style:
                              const TextStyle(color: Colors.red)));
                    } else if (!snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text("Chưa có đoạn chat",
                              style: TextStyle(color: Colors.white70)));
                    }

                    final threads = snapshot.data!;
                    return ListView.builder(
                      itemCount: threads.length,
                      itemBuilder: (context, index) {
                        final thread = threads[index];
                        return ListTile(
                          leading: const Icon(Icons.chat_bubble_outline,
                              color: Colors.white, size: 22),
                          title: Text(
                            thread.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            thread.updatedAt != null
                                ? "${thread.updatedAt!.toLocal()}".split(".")[0]
                                : "Chưa có cập nhật",
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            color: const Color(0xFFEEF3EB),
                            onSelected: (value) async {
                              if (value == "rename") {
                                final controller = TextEditingController(text: thread.name);
                                final newName = await showDialog<String>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Đổi tên đoạn chat"),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(hintText: "Nhập tên mới"),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Hủy"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, controller.text.trim()),
                                        child: const Text("Đổi tên"),
                                      ),
                                    ],
                                  ),
                                );

                                if (newName != null && newName.isNotEmpty) {
                                  // gọi API đổi tên thread
                                  await ThreadApi.renameThread(thread.id, newName);
                                  setState(() {}); // refresh danh sách
                                }
                              } else if (value == "delete") {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Xóa đoạn chat"),
                                    content: Text("Bạn có chắc muốn xóa '${thread.name}' không?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text("Hủy"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        child: const Text("Xóa"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  // gọi API xóa thread
                                  await ThreadApi.deleteThread(thread.id);
                                  setState(() {}); // refresh danh sách
                                }
                              }
                            },
                            itemBuilder: (context) => [
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
                          onTap: () {
                            _selectThread(context, thread.id,thread.name);
                            widget.onThreadSelected(thread.id);
                          },
                        );

                      },
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
                      backgroundImage: userAvatar != null && userAvatar!.isNotEmpty
                          ? NetworkImage(userAvatar!)                // ảnh từ Google/API
                          : const AssetImage("assets/avata.jpeg")    // fallback
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
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white24),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text("Đăng xuất",
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
