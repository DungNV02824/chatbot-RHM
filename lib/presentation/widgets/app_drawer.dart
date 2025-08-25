import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1E1E1E), // nền tối
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header có logo trường
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

              // Menu điều hướng
              ListTile(
                leading: const Icon(Icons.home_outlined, color: Colors.white),
                title: const Text("Trang chủ", style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.edit_note, color: Colors.white),
                title: const Text("Đoạn chat mới", style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.search, color: Colors.white),
                title: const Text("Tìm kiếm đoạn chat", style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Colors.white),
                title: const Text("Cài đặt", style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),

              const Divider(color: Colors.white24),

              // Danh sách đoạn chat
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("Đoạn Chat",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                      title: const Text(
                        "Cuộc trò chuyện mới",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        "25/08",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      onTap: () {},
                    );
                  },
                ),
              ),

              const Divider(color: Colors.white24),

              // User info với avatar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage("assets/avata.jpeg"),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Nguyễn Văn Đúng ",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text("DungNV@example.com",
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
