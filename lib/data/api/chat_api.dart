import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
class ChatApi {
  static const String _baseUrl = "${AppConstants.baseUrl}chat";

  static Future<Map<String, dynamic>> sendMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final sessionId = prefs.getString("thread_id");
    final roleId = prefs.getString("selected_role_id");
    final name = prefs.getString("threadName");
    debugPrint("roleId: $roleId");
    debugPrint("All prefs: ${prefs.getKeys()}");

    debugPrint("Tên đoạn chat: ${name}");

    if (token == null || sessionId == null || roleId == null) {
      throw Exception("Bạn chưa chọn vai trò hoặc là tạo cuộc trò chuyện. Hãy thử lại nhé !😃");
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "message": message,
        "role": roleId,
        "session_id": sessionId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to send message: ${response.statusCode} - ${response.body}");
    }
  }


  static Future<List<Map<String, dynamic>>> getThreadDetail(String threadId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    final response = await http.get(
      Uri.parse("${AppConstants.baseUrl}threads/$threadId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // giả sử API trả về { "messages": [ {role, content}, ...] }
      return List<Map<String, dynamic>>.from(data["messages"]);
    } else {
      throw Exception("Failed to load thread: ${response.body}");
    }
  }
}
