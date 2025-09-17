import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/ThreadModel.dart';
import '../../core/constants.dart';
class ThreadApi {
  static const String _baseUrl = "${AppConstants.baseUrl}threads/";




  // 📌 Tạo thread mới (gọi sau khi login thành công)
  static Future<ThreadModel> createThread(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token == null) {
      throw Exception("Chưa đăng nhập hoặc token hết hạn!");
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"name": name}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ThreadModel.fromJson(data);
    } else {
      throw Exception("Lỗi tạo thread: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<List<ThreadModel>> fetchThreads() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    print("DEBUG fetchThreads TOKEN: $token");
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        "accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );



    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ThreadModel.fromJson(e)).toList();

    } else {
      throw Exception("Failed to fetch threads: ${response.statusCode}");
    }
  }
  static Future<void> renameThread(String id, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final response = await http.put(
      Uri.parse("${AppConstants.baseUrl}threads/$id/rename"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"name": newName}),
    );
    if (response.statusCode != 200) {
      throw Exception("Lỗi đổi tên: ${response.body}");
    }
  }

  static Future<void> deleteThread(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final response = await http.delete(
      Uri.parse("${AppConstants.baseUrl}threads/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 204) {
      throw Exception("Lỗi xóa: ${response.body}");
    }
  }

}
