import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
class Role {
  final String id;
  final String name;
  final String description;

  Role({required this.id, required this.name, required this.description});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class RoleApi {
  static Future<List<Role>> fetchRoles() async {
    final response = await http.get(Uri.parse("${AppConstants.baseUrl}roles"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List roles = data["roles"];
      return roles.map((r) => Role.fromJson(r)).toList();
    } else {
      throw Exception("Lỗi tải roles");
    }
  }

}
