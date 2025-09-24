import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../data/api/RoleApi.dart';
import '../../core/constants.dart';

class RoleSettingsScreen extends StatelessWidget {
  final Function(String threadId, String threadName)? onThreadCreated;

  const RoleSettingsScreen({super.key, this.onThreadCreated});

  Future<void> _saveRole(String roleId, String roleName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("selected_role_id", roleId);
    await prefs.setString("selected_role_name", roleName);
  }

  Future<void> _createThread(BuildContext context, String roleId, String roleName) async {
    // Lưu role trước
    await _saveRole(roleId, roleName);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn chưa đăng nhập!")),
      );
      return;
    }

    // Tạo thread với tên mặc định
    final response = await http.post(
      Uri.parse("${AppConstants.baseUrl}threads/"),
      headers: {
        "Content-Type": "application/json; charset=UTF-8", // ✅ thêm charset UTF-8
        "Authorization": "Bearer $token",
      },
      body: utf8.encode(jsonEncode({
        "name": "Cuộc trò chuyện mới",
      })), // ✅ encode UTF-8
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)); // ✅ decode UTF-8
      final threadId = data["id"];
      final threadName = data["name"];

      await prefs.setString("thread_id", threadId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tạo vai trò mới thành công",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blueAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(12),
        ),
      );

      // Gọi callback nếu có
      if (onThreadCreated != null) {
        onThreadCreated!(threadId, threadName);
      }

      // 👉 Chuyển đến màn hình chat
      Navigator.pushReplacementNamed(
        context,
        "/chat",
        arguments: {
          "threadId": threadId,
          "threadName": threadName,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tạo thread: ${utf8.decode(response.bodyBytes)}")), // ✅ decode UTF-8
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chọn vai trò",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: FutureBuilder(
        future: RoleApi.fetchRoles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else {
            final roles = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: roles.length,
              separatorBuilder: (context, index) =>
              const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final role = roles[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      child: const Icon(Icons.person_outline,
                          color: Colors.blueAccent),
                    ),
                    title: Text(
                      role.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      role.description,
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                    onTap: () => _createThread(context, role.id, role.name),

                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}